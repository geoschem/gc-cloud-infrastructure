output "state_bucket_id" {
	value = module.state_bucket.bucket_id
}

output "lock_table_id" {
	value = module.state_lock_table.table_id
}