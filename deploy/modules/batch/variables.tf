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
variable "s3_path" {
    description = "path to upload run directory to"
}
variable "job_type" {
    description = "type of batch job (eg. container or multinode)"
    default = "container"
}
variable "compute_type" {
    description = "type of ec2 instances (eg. SPOT or EC2)"
    default = "SPOT"
}
variable "ec2_key_pair" {
    description = "name of ec2 key pair if you want to be able to ssh into batch instances (eg. your_key.pem)"
    default = null
}
variable "volume_size" {
    description = "size of the ebs volume for batch job in GB (eg. 200)"
}
variable "shared_memory_size" {
    description = "size of the shared memory volume for batch job in MB (eg. 64)"
    default = 64
}
variable "resolution" {
    description = "Primary resolution is an integer value (eg. 24 ~ 4x5, 48 ~ 2x2.25, 90 ~ 1x1.25, 180 ~ 1/2 deg, 360 ~ 1/4 deg)"
    default = 48
}
variable "num_cores_per_node" {
    description = "number of cores per node (eg. 6)"
    default = 48
}
variable "num_nodes" {
    description = "number of nodes -- currently can only do 1"
    default = 1
}
variable "tag_name" {
    description = "tag name for git checkout"
    default = "13.2.1"
}
variable "allocation_strategy" {
    description = "allocation strategy for ec2 instance deployment (eg. price, capacity)"
    default = "BEST_FIT"
}
variable "compute_resource_tags" {
    description = "tag used to name ec2 instances (eg. lae_ec2_instance)"
    default = null
}

