output "access_key" {
    value = aws_iam_access_key.access_key.id
}

output "secret_access_key" {
    value = aws_iam_access_key.access_key.secret
}