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
# vpc items -- TODO: for now using default vpc and subnets, 
# but may be good to create purpose built vpc
# ==============================================================
data "aws_vpc" "default" {# fetch default vpc
  default = true
}
data "aws_subnet_ids" "all_default_subnets" { # fetch default subnets
  vpc_id = data.aws_vpc.default.id
}
module "benchmarks_security_group" { # TODO: should change to common sg
    source = "./modules/security-group"
    vpc_id = data.aws_vpc.default.id
    name = "benchmarks-cloud-sg"
    description = "security group used for infrastructure related to running benchmarks"
    # TODO: tighten to specific ips?
    ingress_cidr_blocks = ["0.0.0.0/0"]
}

# ==============================================================
# s3 Bucket
# ==============================================================
module "benchmarks_bucket" {
    source = "./modules/s3/bucket"
    bucket_name = var.benchmarks_bucket
    bucket_acl = "private"
    enable_versioning = false
}

module "benchmarks_ecr_repository" { # could potentially make public to save on cost
    source = "./modules/ecr"
    repository_name ="${var.benchmarks_name_prefix}-repository"
}
module "batch_benchmark_artifacts" {
    source = "./modules/batch"
    name_prefix = var.benchmarks_name_prefix
    subnet_ids = data.aws_subnet_ids.all_default_subnets.ids
    ami_id = null # currently using default ami
    instance_types = ["c5"]
    security_group_id = module.benchmarks_security_group.security_group_id
    timeout_seconds = 86400 # 24 hour timeout for jobs
    docker_image = "${module.benchmarks_ecr_repository.repository_url}:latest" # TODO - use version tag
    container_cpu = 48
    container_memory = 98304
    container_properties_file = "../../modules/batch/container-properties/container-properties.json"
    region = data.aws_region.current.name
    log_retention_days = 1
}

module "data_sync_ecr_repository" { # could potentially make public to save on cost
    source = "./modules/ecr"
    repository_name = "input-data-sync-repository"
}
module "batch_data_sync_artifacts" {
    source = "./modules/batch"
    name_prefix = "input-data-sync"
    subnet_ids = data.aws_subnet_ids.all_default_subnets.ids
    ami_id = null # currently using default ami
    instance_types = ["c5"]
    security_group_id = module.benchmarks_security_group.security_group_id
    timeout_seconds = 86400 # 24 hour timeout for jobs
    docker_image = "${module.benchmarks_ecr_repository.repository_url}:latest" # TODO - use version tag
    container_cpu = 48
    container_memory = 98304
    container_properties_file = "../../modules/batch/container-properties/container-properties.json"
    region = data.aws_region.current.name
    log_retention_days = 1
}

module "gchp_image_builder" {
    source = "./modules/ec2-image-builder"
    component_name = "InstallSpackEnvironment"
    name_prefix = "spackenv"
    component_platform = "Linux"
    component_version = "1.0.1"
    component_file = "../../modules/ec2-image-builder/components/install-spack-component.yaml"
    security_group_id = module.benchmarks_security_group.security_group_id
    subnet_id = tolist(data.aws_subnet_ids.all_default_subnets.ids)[0]
    recipe_name = "geoschem_deps-pcluster_ami-x86_64-alinux2-intel_latest-intelmpi_latest"
}
