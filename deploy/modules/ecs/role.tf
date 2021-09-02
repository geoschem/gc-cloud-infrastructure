# task execution role
resource "aws_iam_role" "ecs_benchmarks_cloud_role" {
    name = "ecs-benchmarks-cloud-task-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                    "ecs-tasks.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ecs_benchmarks_cloud_policy" {
    name = "ecs-benchmarks-cloud-policy"
    path = "/"
    description = "IAM policy for access rules from ecs tasks"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecs:*",
                "ecr:*",
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
    role = aws_iam_role.ecs_benchmarks_cloud_role.name
    policy_arn = aws_iam_policy.ecs_benchmarks_cloud_policy.arn
}
