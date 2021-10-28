# ==============================================================
# harvard specific input variables should 
# be declared in this file
# ==============================================================

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
    backend "s3" {
        bucket = "benchmarks-cloud-tfstate"
        key = "tfstate/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "gc-benchmarks-tfstate-lock"
        encrypt = true
    }
}

module "harvard" {
    source = "../.."
    benchmarks_bucket = "benchmarks-cloud"
    benchmarks_name_prefix = "benchmarks-cloud"
}