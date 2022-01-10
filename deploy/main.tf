# ==============================================================
# All common infrastructure inputs should 
# be declared in this file
# ==============================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ==============================================================
# terraform state persistence
# ==============================================================
terraform {
    required_version = ">= 1.0.5" # at least have v1.0.5 of terraform
    required_providers {
        aws = {
            version = ">= 3.63.0" # at least have v3.56.0 of aws provider
            source = "hashicorp/aws"
        }
    }
}

# ==============================================================
# local variables 
# ==============================================================
locals {
    # variables used to determine if a module should only be for 
    # one organization
    only_washu = var.organization == "washu" ? 1 : 0
    only_harvard = var.organization == "harvard" ? 1 : 0
    all_environments = 1
    AQACF_account_number = "" #TODO replace with real account #
}


# ==============================================================
# vpc items -- TODO: for now using default vpc and subnets, 
# but may be good to create purpose built vpc
# ==============================================================
data "aws_vpc" "default" {# fetch default vpc
  default = true
}
data "aws_subnet_ids" "all_default_subnets" { # fetch default subnets
  vpc_id = data.aws_vpc.default.id
}
module "default_security_group" { # TODO: should change to common sg
    count = local.all_environments
    source = "./modules/security-group"
    vpc_id = data.aws_vpc.default.id
    name = "default-gc-cloud-sg"
    description = "security group used for infrastructure related to running benchmarks"
    # TODO: tighten to specific ips?
    ingress_cidr_blocks = ["0.0.0.0/0"]
}

# ==============================================================
# s3 Bucket
# ==============================================================
module "benchmarks_bucket" {
    source = "./modules/s3/bucket"
    count = local.all_environments
    bucket_name = var.benchmarks_bucket
    bucket_acl = "private"
    enable_versioning = false
    expiration_settings = [{
        prefix = "benchmarks/1Day/"
        days = 90
    }]
}

# ==============================================================
# benchmark items
# ==============================================================
module "benchmarks_ecr_repository" { # could potentially make public to save on cost
    source = "./modules/ecr"
    count = local.all_environments
    repository_name ="${var.benchmarks_name_prefix}-repository"
}
module "github_service_user" { # could potentially make public to save on cost
    source = "./modules/iam/user"
    count = local.only_harvard
    name ="${var.benchmarks_name_prefix}-github-user"
    permitted_services = "\"states:*\""
}

module "batch_benchmark_artifacts" {
    source = "./modules/benchmarks"
    count = local.all_environments
    name_prefix = var.benchmarks_name_prefix
    subnet_ids = data.aws_subnet_ids.all_default_subnets.ids
    ami_id = null # currently using default ami
    instance_types = ["optimal"]
    security_group_id = module.default_security_group[0].security_group_id
    timeout_seconds = 86400 # 24 hour timeout for jobs
    docker_image = "${module.benchmarks_ecr_repository[0].repository_url}:latest" # TODO - use version tag
    container_cpu = 48
    container_memory = 98304
    container_properties_file = "../../modules/batch/container-properties/container-properties.json"
    region = data.aws_region.current.name
    log_retention_days = 5
    s3_path = "s3://${var.benchmarks_bucket}" 
    ec2_key_pair = "lestrada_keypair"
    volume_size = 300
    shared_memory_size = 10000
    resolution = 24
    num_cores_per_node = 6
    step_fn_definition_file = "../../modules/step-function/state-machine-definitions/cloud-benchmarks.json"
    enable_step_function = true
    sns_topic = module.gcst_sns_topic[0].arn
}

# ==============================================================
# input data sync items
# ==============================================================
module "batch_multinode_run" {
    source = "./modules/batch"
    count = 0 # TODO change this
    name_prefix = "gchp-multinode"
    subnet_ids = data.aws_subnet_ids.all_default_subnets.ids
    ami_id = null # currently using default ami
    instance_types = ["c5"]
    security_group_id = module.default_security_group[0].security_group_id
    timeout_seconds = 86400 # 24 hour timeout for jobs
    docker_image = "${module.benchmarks_ecr_repository[0].repository_url}:latest" # TODO - use version tag
    container_cpu = 48
    container_memory = 98304
    container_properties_file = "../../modules/batch/container-properties/container-properties.json"
    region = data.aws_region.current.name
    log_retention_days = 1
    s3_path = "s3://${var.benchmarks_bucket}" 
    compute_type = "EC2"
    volume_size = 30
}
# ==============================================================
# input data sync items
# ==============================================================
module "data_sync_ecr_repository" { # could potentially make public to save on cost
    source = "./modules/ecr"
    count = local.only_washu
    repository_name = "input-data-sync-repository"
}
module "batch_data_sync_artifacts" {
    source = "./modules/batch"
    count = local.only_washu
    name_prefix = "input-data-sync"
    subnet_ids = data.aws_subnet_ids.all_default_subnets.ids
    ami_id = null # currently using default ami
    instance_types = ["c5"]
    security_group_id = module.default_security_group[0].security_group_id
    timeout_seconds = 86400 # 24 hour timeout for jobs
    docker_image = "${module.data_sync_ecr_repository[0].repository_url}:latest" # TODO - use version tag
    container_cpu = 48
    container_memory = 98304
    container_properties_file = "../../modules/batch/container-properties/container-properties.json"
    region = data.aws_region.current.name
    log_retention_days = 1
    s3_path = "s3://${var.benchmarks_bucket}" # TODO: update batch module to be more flexible 
    volume_size = 30
}

# ==============================================================
# image builder items
# ==============================================================
module "gchp_image_builder" {
    source = "./modules/ec2-image-builder"
    count = local.all_environments
    component_name = "InstallSpackEnvironment"
    name_prefix = "spackenv"
    component_platform = "Linux"
    builder_version = "1.0.2" # TODO: figure out a way to stop needing to change this with every update 
    component_file = "../../modules/ec2-image-builder/components/install-spack-component.yaml"
    security_group_id = module.default_security_group[0].security_group_id
    subnet_id = tolist(data.aws_subnet_ids.all_default_subnets.ids)[0]
    recipe_name = "geoschem_deps-pcluster_ami-x86_64-alinux2-intel_latest-intelmpi_latest"
}

# ==============================================================
# AQACF items
# ==============================================================
module "AQACF_bucket" {
    source = "./modules/s3/bucket"
    count = local.only_washu
    bucket_name = "${var.organization}-aqacf-data"
    enable_versioning = false
    bucket_policy = <<POLICY
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "AQACF permissions",
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::${local.AQACF_account_number}:root"
         },
         "Action": [
            "s3:GetBucketLocation",
            "s3:ListBucket"
         ],
         "Resource": [
            "arn:aws:s3:::${var.organization}-aqacf-data"
         ]
      },
      {
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::${local.AQACF_account_number}:root"
         },
         "Action": [
            "s3:GetObject"
         ],
         "Resource": [
            "arn:aws:s3:::${var.organization}-aqacf-data/*"
         ]
      }
   ]
}
POLICY
}

# ==============================================================
# Billing alarm items
# ==============================================================
module "gcst_sns_topic" {
    source = "./modules/sns"
    count = local.only_harvard
    sns_topic_name = "gcst-sns-topic"
}
module "cloudwatch_cost_alarm" {
    source = "./modules/cloudwatch/alarms"
    count = local.only_harvard
    alarm_name = "account-billing-alarm"
    metric_name = "EstimatedCharges"
    metric_namespace = "AWS/Billing"
    currency = "USD"
    threshold = "450" 
    description = "This metric monitors total estimated monthly costs"
    sns_topic_arn = module.gcst_sns_topic[0].arn
    account_number = data.aws_caller_identity.current.account_id
}