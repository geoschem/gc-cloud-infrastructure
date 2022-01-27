variable "name_prefix" {
    description = "name prefix for cloudwatch rule"
}
variable "description" {
    description = "description of cloudwatch rule"
}
variable "target_arn" {
    description = "arn for rule target"
}
variable "schedule_expression" {
    description = "cron expression for triggering rule"
}
variable "is_enabled" {
    description = "is rule enabled?"
    default = true
}
variable "batch_job_definition" {
    description = "batch job definition name"
}