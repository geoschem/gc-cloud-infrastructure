resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name

    acl = var.bucket_acl
    versioning {
        enabled = var.enable_versioning
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