module "iam_policy" {
    source = "../policy"
    policy = var.policy
    name   = "${var.name_prefix}_policy"
}

resource "aws_iam_role" "cross_account_iam_role" {
    name = "${var.name_prefix}_role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Effect    = "Allow",
            Action    = "sts:AssumeRole",
            Principal = { "AWS" : "arn:aws:iam::${var.account_id}:root" }
        }]
    })
}
resource "aws_iam_role_policy_attachment" "role_attachment" {
    role       = aws_iam_role.cross_account_iam_role.name
    policy_arn = module.iam_policy.policy_arn
}
