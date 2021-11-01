# Role for underlying EC2 instances
resource "aws_iam_role" "ec2_builder_role" {
    name = "${var.name_prefix}-role"
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
    name = "${var.name_prefix}-instance-profile"
    role = aws_iam_role.ec2_builder_role.name
}

# Attach the s3 full access and EC2 container service policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
    role = aws_iam_role.ec2_builder_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "image_builder_policy_attachment" {
    role = aws_iam_role.ec2_builder_role.name
    policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
    role = aws_iam_role.ec2_builder_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
    role = aws_iam_role.ec2_builder_role.name
    policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
