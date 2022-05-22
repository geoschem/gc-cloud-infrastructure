data "archive_file" "zip_code" {
  type        = "zip"
  source_dir  = var.code_path
  output_path = "${var.packages_path}/code_pkg.zip"
  excludes    = var.code_zip_exclude
}

data "archive_file" "zip_layers" {
  type        = "zip"
  source_dir  = "${var.packages_path}/layers"
  output_path = "${var.packages_path}/layers.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename         = data.archive_file.zip_code.output_path
  function_name    = "${var.name_prefix}-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  source_code_hash = data.archive_file.zip_code.output_base64sha256
  runtime          = var.runtime
}

resource "aws_lambda_function_url" "lambda_url" {
  count              = var.enable_lambda_function_url == true ? 1 : 0
  function_name      = aws_lambda_function.lambda_function.function_name
  authorization_type = var.function_url_authentication
  cors {
    allow_origins = ["*"]
    allow_methods = var.allow_methods
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = var.log_expiration_days
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = data.archive_file.zip_layers.output_path
  layer_name          = "${var.name_prefix}-layer"
  compatible_runtimes = [var.runtime]
}
