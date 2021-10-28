# ==============================================================
# harvard specific input variables should 
# be declared in this file
# ==============================================================

provider "aws" {
    region = "us-east-1"
}

# ==============================================================
# terraform state persistence
# ==============================================================
terraform {
    backend "s3" {
        bucket = "washu-cloud-tfstate"
        key = "tfstate/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "washu-cloud-tfstate-lock"
        encrypt = true
    }
}

module "washu" {
    source = "../.."
    benchmarks_bucket = "washu-benchmarks-cloud"
    benchmarks_name_prefix = "washu-benchmarks-cloud"
}