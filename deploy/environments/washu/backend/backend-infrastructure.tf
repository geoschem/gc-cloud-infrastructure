# NOTE - this file should be used to configure and manage artifacts needed to 
# securely store the terraform backend tfstate file for the benchmarking infrastructure.    
#
# ALSO - it's important to note that the artifacts managed by this terraform template
# have their state stored in the adjacent terraform.tfstate file.    This file MUST be
# commited to source control and kept up to date with PRs that immediately follow any
# changes to the state. Talk to lae if you have any questions

provider "aws" {
    region = "us-east-1"
}

terraform {
    required_version = ">= 1.0.5" # must at least have v1.0.5 of terraform
    required_providers {
        aws = {
            version = ">= 3.56.0" # at least have v3.56.0 of aws provider
            source = "hashicorp/aws"
        }
    }
}

module "terraform_state" {
    source = "../../../modules/terraform-state"
    
    bucket_name = "washu-cloud-tfstate"
    lock_table_name = "washu-cloud-tfstate-lock"
}