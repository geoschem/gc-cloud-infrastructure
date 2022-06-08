# service role
resource "aws_iam_role" "default_sfn_role" {
  name = "${var.name}-sfn-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "states.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# logging policy
resource "aws_iam_policy" "sfn_policy" {
  name = "${var.name}-sfn-policy"
  path = "/"
  description = "IAM policy for accessing various services from step functions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "batch:*",
        "sns:*",
        "iam:PassRole",
        "logs:*",
        "events:*",
        "states:*",
        "lambda:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "sfn_policy" {
  role = aws_iam_role.default_sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}
