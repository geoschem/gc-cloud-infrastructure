# ==============================================================
# cloud provider
# ==============================================================
provider "aws" {
    region = "us-east-1"
}

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
# s3 Bucket
# ==============================================================
module "benchmarks_bucket" {
  source = "./modules/s3/bucket"
  bucket_name = "benchmarks-cloud"
  bucket_acl = "private"
  enable_versioning = false
}