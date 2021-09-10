variable "name_prefix" {
    description = "name prefix for batch items"
}
variable "subnet_ids" {
    description = "array of subnets to use for ec2 instance"
}
variable "ami_id" {
    description = "id of the ami to launch with"
}
variable "instance_types" {
    description = "array instance types to launch on"
}
variable "security_group_id" {
    description = "id of security group"
}
variable "timeout_seconds" {
    description = "number of seconds before a job times out"
}
variable "docker_image" {
    description = "url to docker image in ecr repository"
}
variable "container_cpu" {
    description = "cpu to give the container (in vcpu)"
}
variable "container_memory" {
    description = "memory to give the container (in MiB)"
}
variable "container_properties_file" {
    description = "file path for container properties file"
}
variable "region" {
    description = "region for cloudwatch log group"
}
variable "log_retention_days" {
    description = "number of days to retain logs in cloudwatch"
}
