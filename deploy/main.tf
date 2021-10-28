# ==============================================================
# cloud provider
# ==============================================================
provider "aws" {
    region = "us-east-1"
}

data "aws_region" "current" {}

# ==============================================================
# terraform state persistence
# ==============================================================
terraform {
    required_version = ">= 1.0.5" # at least have v1.0.5 of terraform
    required_providers {
        aws = {
            version = ">= 3.56.0" # at least have v3.56.0 of aws provider
            source = "hashicorp/aws"
        }
    }
    backend "s3" {
        bucket = "benchmarks-cloud-tfstate"
        key = "tfstate/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "gc-benchmarks-tfstate-lock"
        encrypt = true
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
module "benchmarks_security_group" {
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
    bucket_name = "benchmarks-cloud"
    bucket_acl = "private"
    enable_versioning = false
}

module "ecr_repository" { # could potentially make public to save on cost
    source = "./modules/ecr"
    repository_name ="benchmarks-cloud-repository"
}
module "batch_artifacts" {
    source = "./modules/batch"
    name_prefix = "benchmarks-cloud"
    subnet_ids = data.aws_subnet_ids.all_default_subnets.ids
    ami_id = null # currently using default ami
    instance_types = ["c5"]
    security_group_id = module.benchmarks_security_group.security_group_id
    timeout_seconds = 86400 # 24 hour timeout for jobs
    docker_image = "${module.ecr_repository.repository_url}:latest" # TODO - use version tag
    container_cpu = 48
    container_memory = 98304
    container_properties_file = "./modules/batch/container-properties/container-properties.json"
    region = data.aws_region.current.name
    log_retention_days = 1
}

# # ==============================================================
# # ecs item(s)
# # ==============================================================
# module "ecs_artifacts" {
#     source = "./modules/ecs"
#     ecs_name_prefix = "benchmarks-cloud"
#     security_group_id = module.benchmarks_security_group.security_group_id
#     subnet_ids = ["subnet-3198906c", "subnet-66279169"] # TODO - add others?
#     cpu = "48"
#     memory = "96000"
#     task_definition_file = "./modules/ecs/task-definition/task-definition.json"
#     region = data.aws_region.current.name
#     docker_image = "${module.ecr_repository.repository_url}:latest" # TODO - use version tag
# }
