module "state_bucket" {
    source = "../s3/bucket"
    
    bucket_name = var.bucket_name
    bucket_acl = "private"
    enable_versioning = true
    encryption_algorithm = ["AES256"]
}

module "state_lock_table" {
    source = "../dynamo"
    
    table_name = var.lock_table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attributes = [
        {
            name = "LockID"
            type = "S"
        }
    ]
}