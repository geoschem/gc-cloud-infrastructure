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
module "benchmarks_security_group" {
    source = "./modules/security-group"
    vpc_id = "vpc-09cea772"
    name = "benchmarks-cloud-sg"
    description = "security group used for infrastructure related to running benchmarks"
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

# ==============================================================
# ecs item(s)
# ==============================================================
module "ecs_artifacts" {
    source = "./modules/ecs"
    ecs_name_prefix = "benchmarks-cloud"
    security_group_id = module.benchmarks_security_group.security_group_id
    subnet_ids = ["subnet-3198906c", "subnet-66279169"] # TODO - add others?
    cpu = "48"
    memory = "96000"
    task_definition_file = "./modules/ecs/task-definition/task-definition.json"
    region = data.aws_region.current.name
    
}
