// API GW
resource "aws_apigatewayv2_api" "lambda" {
  name          = "${var.name_prefix}-gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "${var.name_prefix}-production"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = var.lambda_function_arn
  integration_type   = "AWS_PROXY"
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "route" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = var.dns_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert_api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  depends_on = [
    aws_acm_certificate.cert_api
  ]
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.lambda.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.lambda.id
}

// ACM
resource "aws_acm_certificate" "cert_api" {
  domain_name       = var.dns_name
  validation_method = "DNS"

  tags = {
    Name = var.dns_name
  }
}

resource "aws_acm_certificate_validation" "cert_api" {
  certificate_arn = aws_acm_certificate.cert_api.arn
}

// Route53

data "aws_route53_zone" "api" {
  name         = var.dns_name
  private_zone = false
}

resource "aws_route53_record" "cert_api_validations" {
  allow_overwrite = true
  count           = length(aws_acm_certificate.cert_api.domain_validation_options)

  zone_id = data.aws_route53_zone.api.zone_id
  name    = element(aws_acm_certificate.cert_api.domain_validation_options.*.resource_record_name, count.index)
  type    = element(aws_acm_certificate.cert_api.domain_validation_options.*.resource_record_type, count.index)
  records = [element(aws_acm_certificate.cert_api.domain_validation_options.*.resource_record_value, count.index)]
  ttl     = 60
}

resource "aws_route53_record" "api-a" {
  name    = aws_apigatewayv2_domain_name.api.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.api.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
