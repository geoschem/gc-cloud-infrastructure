variable bucket_name {
    description = "must be a globally unique name for the bucket"
}

variable bucket_acl {
    description = "The canned ACL to apply. Valid values are private, public-read, public-read-write, aws-exec-read, authenticated-read, and log-delivery-write."
    default = null
}
variable bucket_policy {
    description = "json policy for bucket"
    default = null
}

variable enable_versioning {
    default = "Suspended"
    description = "set to Enabled to ensure you can see the full revision history of bucket objects"
}

variable encryption_algorithm {
    description = "set array to either [\"AES256\"] or [\"aws:kms\"] to enable server-side encryption for the bucket"
    default = null
}
variable expiration_settings {
    description = "settings for object expiration in the bucket. Each object in array must contain a prefix and days attribute"
    default = []
}