# role for batch to access ec2, ecr, etc
resource "aws_iam_role" "batch_role" {
    name = "${var.name_prefix}-batch-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                    "batch.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# attach batch service policy to role 
resource "aws_iam_role_policy_attachment" "batch_policy_attachment" {
    role = aws_iam_role.batch_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}
# Role for underlying EC2 instances
resource "aws_iam_role" "ec2_role" {
    name = "${var.name_prefix}-ec2-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Assign the EC2 role to the EC2 profile
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.name_prefix}-ec2-profile"
    role = aws_iam_role.ec2_role.name
}

# Attach the s3 full access and EC2 container service policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Role for jobs 
resource "aws_iam_role" "job_role" {
    name = "${var.name_prefix}-job-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            }
        }
    ]
}
EOF
}
# S3 open access policy
resource "aws_iam_policy" "job_policy" {
  name   = "${var.name_prefix}-job-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
# Attach the policy to the job role
resource "aws_iam_role_policy_attachment" "job_policy_attachment" {
  role = aws_iam_role.job_role.name
  policy_arn = aws_iam_policy.job_policy.arn
}

