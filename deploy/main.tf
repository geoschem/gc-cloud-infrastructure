# ==============================================================
# All common infrastructure inputs should 
# be declared in this file
# ==============================================================

data "aws_region" "current" {}

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
    count = local.only_harvard
    bucket_name = var.benchmarks_bucket
    bucket_acl = "private"
    enable_versioning = false
}

# ==============================================================
# benchmark items
# ==============================================================
module "benchmarks_ecr_repository" { # could potentially make public to save on cost
    source = "./modules/ecr"
    count = local.only_harvard
    repository_name ="${var.benchmarks_name_prefix}-repository"
}

module "batch_benchmark_artifacts" {
    source = "./modules/batch"
    count = local.only_harvard
    name_prefix = var.benchmarks_name_prefix
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
    spot_iam_fleet_role = null
    compute_type = "EC2"
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
            "s3:ListBucket",
            "s3:GetObject"
         ],
         "Resource": [
            "arn:aws:s3:::${var.organization}-aqacf-data"
         ]
      }
   ]
}
POLICY
}