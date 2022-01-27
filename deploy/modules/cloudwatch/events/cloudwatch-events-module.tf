resource "aws_cloudwatch_event_rule" "rule" {
  name_prefix   = var.name_prefix
  description   = var.description
  schedule_expression = var.schedule_expression
  is_enabled = var.is_enabled
}

resource "aws_cloudwatch_event_target" "target" {
  rule     = aws_cloudwatch_event_rule.rule.name
  arn      = var.target_arn
  role_arn = aws_iam_role.cloudwatch_role.arn
  batch_target {
    job_definition = var.batch_job_definition
    job_name = "${var.name_prefix}-invokation"
  }
}
resource "aws_iam_role" "cloudwatch_role" {
    name = "${var.name_prefix}-cloudwatch-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
resource "aws_iam_policy" "rule_policy" {
  name   = "${var.name_prefix}-job-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "batch:SubmitJob"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "policy_attachment" {
    role = aws_iam_role.cloudwatch_role.name
    policy_arn = aws_iam_policy.rule_policy.arn
}
