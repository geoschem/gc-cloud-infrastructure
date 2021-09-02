resource "aws_iam_user" "iam_user" {
    name = var.name
}

resource "aws_iam_access_key" "access_key" {
    user = aws_iam_user.iam_user.name
}

resource "aws_iam_user_policy" "iam_user_policy" {
    name = "${var.name}-policy"
    user = aws_iam_user.iam_user.name

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [${var.permitted_services}],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}