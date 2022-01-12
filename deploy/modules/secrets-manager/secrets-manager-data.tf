data "aws_secretsmanager_secret" "secret_metadata" {
  arn = var.secret_arn
}

data "aws_secretsmanager_secret_version" "secret" {
  secret_id = data.aws_secretsmanager_secret.secret_metadata.id
}