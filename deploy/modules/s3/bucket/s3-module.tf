resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "policy" {
    count = var.bucket_policy != null ? 1 : 0
    bucket = aws_s3_bucket.bucket.id
    policy = var.bucket_policy
}

resource "aws_s3_bucket_acl" "bucket_acl" {
    bucket = aws_s3_bucket.bucket.id
    acl    = var.bucket_acl
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.enable_versioning
  }
}

# conditionally add encryption if encryption algorithm is given
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
    count = var.encryption_algorithm != null ? 1 : 0
    bucket = aws_s3_bucket.bucket.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = var.encryption_algorithm
        }
    }
}

# conditionally add lifecycle rule to bucket items
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_rules" {
  bucket = aws_s3_bucket.bucket.id
    dynamic "rule" {
        for_each = var.expiration_settings
        content {
            id = "rule-${index(var.expiration_settings, rule.value)}"
            expiration {
                days = rule.value["days"]
            }
            filter {
                prefix = rule.value["prefix"]
            }
            status = "Enabled"
        }
    }
}