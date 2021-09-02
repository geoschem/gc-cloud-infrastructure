variable "ecs_name_prefix" {
    description = "name prefix for ecs items"
}
variable "security_group_id" {
    description = "id of security group for cluster"
}
variable "subnet_ids" {
    description = "array of subnet ids to use for instance"
}
variable "cpu" {
    description = "number of cpus (eg. 48)"
}
variable "memory" {
    description = "amount of memory for container (in MB)"
}
variable "task_definition_file" {
    description = "Path to task definition json file"
}
variable "region" {
    description = "aws region to use for various artifacts"
}