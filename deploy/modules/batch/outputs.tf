output "batch_job_definition_name" {
    value = aws_batch_job_definition.job.name
}
output "batch_job_queue_name" {
    value = aws_batch_job_queue.job_queue.name
}