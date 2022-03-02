# ==============================================================
# inout data variables
# ==============================================================
data "aws_vpc" "default" {# fetch default vpc
  default = true
}
data "aws_subnet_ids" "subnets" {
  vpc_id = local.vpc_id
}
# conditionally set whether to use the default vpc or a purpose built vpc
locals {
  vpc_id = var.use_default_vpc ? data.aws_vpc.default.id : module.vpc_items[0].vpc_id
}
# ==============================================================
# benchmarking modules/ infrastructure
# ==============================================================
# email notification service for benchmarking
# Note: subscriptions must be handled manually
module "benchmarks_sns_topic" {
  source         = "../sns"
  sns_topic_name = "${var.name_prefix}-sns-topic"
}
# step function for handling various states in the benchmarking process
module "step_function" {
  source          = "../step-function"
  count           = var.enable_step_function ? 1 : 0
  name            = "${var.name_prefix}-workflow"
  definition_file = var.step_fn_definition_file
  state_machine_definition_vars = {
    job_definition_name_on_demand = module.benchmarks_on_demand.batch_job_definition_name
    job_queue_on_demand           = module.benchmarks_on_demand.batch_job_queue_name
    job_definition_name_spot      = module.benchmarks_spot.batch_job_definition_name
    job_queue_spot                = module.benchmarks_spot.batch_job_queue_name
    sns_topic_arn                 = module.benchmarks_sns_topic.arn
  }
}
# batch infrastructure for on demand compute instances
module "benchmarks_on_demand" {
  source                    = "../batch"
  name_prefix               = var.name_prefix
  subnet_ids                = data.aws_subnet_ids.subnets.ids
  ami_id                    = var.ami_id
  instance_types            = var.instance_types
  security_group_id         = module.benchmarks_security_group.security_group_id
  timeout_seconds           = var.timeout_seconds
  docker_image              = var.docker_image
  container_cpu             = var.container_cpu
  container_memory          = var.container_memory
  container_properties_file = var.container_properties_file
  region                    = var.region
  log_retention_days        = var.log_retention_days
  s3_path                   = var.s3_path
  ec2_key_pair              = var.ec2_key_pair
  volume_size               = var.volume_size
  shared_memory_size        = var.shared_memory_size
  compute_type              = "EC2"
  resolution                = var.resolution
  num_cores_per_node        = var.num_cores_per_node
  launch_script_path        = "../../modules/batch/launch-scripts/fsx-mount-script.sh"
  fsx_address               = var.fsx_address
  compute_resource_tags = {
    Name = "cloud-benchmarks-on-demand"
  }
  depends_on = [module.vpc_items] # need vpc and subnets created before creation
}
# batch infrastructure for spot compute instances

module "benchmarks_spot" {
  source                    = "../batch"
  name_prefix               = "${var.name_prefix}-spot"
  subnet_ids                = data.aws_subnet_ids.subnets.ids
  ami_id                    = var.ami_id
  instance_types            = var.instance_types
  security_group_id         = module.benchmarks_security_group.security_group_id
  timeout_seconds           = var.timeout_seconds
  docker_image              = var.docker_image
  container_cpu             = var.container_cpu
  container_memory          = var.container_memory
  container_properties_file = var.container_properties_file
  region                    = var.region
  log_retention_days        = var.log_retention_days
  s3_path                   = var.s3_path
  ec2_key_pair              = var.ec2_key_pair
  volume_size               = var.volume_size
  shared_memory_size        = var.shared_memory_size
  resolution                = var.resolution
  num_cores_per_node        = var.num_cores_per_node
  allocation_strategy       = "SPOT_CAPACITY_OPTIMIZED" # lowers chance of interruptions
  launch_script_path        = "../../modules/batch/launch-scripts/fsx-mount-script.sh"
  fsx_address               = var.fsx_address
  compute_resource_tags = {
    Name = "cloud-benchmarks-spot"
  }
  depends_on = [module.vpc_items] # need vpc and subnets created before creation
}

# ==============================================================
# network items 
# ==============================================================
# purpose built security group for benchmarks
module "benchmarks_security_group" {
    source = "../security-group"
    vpc_id = local.vpc_id
    name = "${var.name_prefix}-sg"
    description = "security group used for infrastructure related to running benchmarks"
    ingress_rules = [{ #ssh rule
        protocol = "tcp"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"] # TODO: tighten to specific ips?
        self = false
        security_group_ids = null
    },
    { #fsx rule
        protocol = "tcp"
        from_port = 988
        to_port = 988
        cidr_blocks = null
        self = true
        security_group_ids = null
    },
    { #fsx rule
        protocol = "tcp"
        from_port = 1021
        to_port = 1023
        cidr_blocks = null
        self = true
        security_group_ids = null
    },
    { #fsx rule
        protocol = "tcp"
        from_port = 988
        to_port = 988
        cidr_blocks = null
        self = false
        security_group_ids = ["${var.peer_account_number}/${var.peer_security_group_id}"]
    },
    { #fsx rule
        protocol = "tcp"
        from_port = 1021
        to_port = 1023
        cidr_blocks = null
        self = false
        security_group_ids = ["${var.peer_account_number}/${var.peer_security_group_id}"]
    }]
}

# only built if use_default_vpc is set to false
module "vpc_items" {
  source      = "../vpc"
  count       = var.use_default_vpc ? 0 : 1
  cidr_block  = "10.0.0.0/16"
  name_prefix = var.name_prefix
  peering_connection_id = var.peering_connection_id
  public_subnets_info = [{
    cidr_block        = "10.0.0.0/20"
    availability_zone = "us-east-1a"
    },
    {
      cidr_block        = "10.0.16.0/20"
      availability_zone = "us-east-1b"
    },
    {
      cidr_block        = "10.0.32.0/20"
      availability_zone = "us-east-1c"
    },
    {
      cidr_block        = "10.0.48.0/20"
      availability_zone = "us-east-1d"
    },
    {
      cidr_block        = "10.0.64.0/20"
      availability_zone = "us-east-1e"
    },
    {
      cidr_block        = "10.0.80.0/20"
      availability_zone = "us-east-1f"
  }]
}

module "benchmark_registry_table" {
  source = "../dynamo"
  
  table_name = "geoschem_testing"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "InstanceID"
  # only need indexed variables defined eg. primary key
  attributes = [
    {
      name = "InstanceID"
      type = "S"
    }
  ]
}
