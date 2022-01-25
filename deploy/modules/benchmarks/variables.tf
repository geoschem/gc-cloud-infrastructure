
variable "name_prefix" {
  description = "name prefix for batch items"
}
variable "ami_id" {
  description = "id of the ami to launch with"
  default     = null
}
variable "instance_types" {
  description = "array instance types to launch on"
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
variable "s3_path" {
  description = "path to upload run directory to"
}
variable "job_type" {
  description = "type of batch job (eg. container or multinode)"
  default     = "container"
}
variable "ec2_key_pair" {
  description = "name of ec2 key pair if you want to be able to ssh into batch instances (eg. your_key.pem)"
  default     = null
}
variable "volume_size" {
  description = "size of the ebs volume for batch job in GB (eg. 200)"
}
variable "shared_memory_size" {
  description = "size of the shared memory volume for batch job in MB (eg. 64)"
  default     = 64
}
variable "resolution" {
  description = "Primary resolution is an integer value (eg. 24 ~ 4x5, 48 ~ 2x2.25, 90 ~ 1x1.25, 180 ~ 1/2 deg, 360 ~ 1/4 deg)"
  default     = 48
}
variable "num_cores_per_node" {
  description = "number of cores per node (eg. 6)"
  default     = 48
}
variable "num_nodes" {
  description = "number of nodes -- currently can only do 1"
  default     = 1
}
variable "tag_name" {
  description = "tag name for git checkout"
  default     = "13.2.1"
}
variable "enable_step_function" {
  description = "Whether to create a step function with the batch job"
  default     = false
}
variable "step_fn_definition_file" {
  description = "path to step function definition"
  default     = null
}
variable "sns_topic" {
  description = "arn for sns topic used for email notifications"
  default     = null
}
variable "use_default_vpc" {
  description = "use the default vpc for benchmarking items. if false, creates new vpc"
  default     = true
}
variable "peer_account_number" {
  description = "account number of peer account (for sharing of fsx instance)"
}
variable "peer_security_group_id" {
  description = "security group id of peer account (for sharing of fsx instance)"
}
variable "peering_connection_id" {
  description = "vpc peering connection id (only required if creating vpc route table rule)"
  default = null
}
variable "fsx_address" {
  description = "ip address or dns address to the fsx for lustre volume"
}
