resource "aws_iam_role" "marketplace_role" {
    name = "aws-marketplace-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "assets.marketplace.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
    role = aws_iam_role.marketplace_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSMarketplaceAmiIngestion"
}