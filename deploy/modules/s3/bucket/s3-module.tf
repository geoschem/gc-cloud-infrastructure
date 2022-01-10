resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name

    acl = var.bucket_acl
    policy = var.bucket_policy
    versioning {
        enabled = var.enable_versioning
    }

    dynamic "lifecycle_rule" {
        for_each = var.expiration_settings
        content {
            enabled = true
            prefix = lifecycle_rule.value["prefix"]
            expiration {
                days = lifecycle_rule.value["days"]
            }
        }
    }
    # conditionally add encryption if encryption algorithm is given
    dynamic "server_side_encryption_configuration" {
        for_each = var.encryption_algorithm

        content {
            rule {
                apply_server_side_encryption_by_default {
                    sse_algorithm = server_side_encryption_configuration.value
                }
            }
        }
    }
}