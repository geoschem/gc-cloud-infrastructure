variable bucket_name {
	description = "S3 bucket name for storing terraform state"
}

variable lock_table_name {
	description = "DynamoDB table name for transient storage of state locks"
}
