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
      source  = "hashicorp/aws"
    }
  }
}

# ==============================================================
# local variables 
# ==============================================================
locals {
  # variables used to determine if a module should only be for 
  # one organization
  only_washu       = var.organization == "washu" ? 1 : 0
  only_harvard     = var.organization == "harvard" ? 1 : 0
  all_environments = 1
}


# ==============================================================
# vpc items
# ==============================================================
data "aws_vpc" "default" { # fetch default vpc
  default = true
}
data "aws_subnet_ids" "all_default_subnets" { # fetch default subnets
  vpc_id = data.aws_vpc.default.id
}
module "default_security_group" {
  count       = local.all_environments
  source      = "./modules/security-group"
  vpc_id      = data.aws_vpc.default.id
  name        = "default-gc-cloud-sg"
  description = "security group used for infrastructure related to running benchmarks"
  ingress_rules = [{ #ssh rule
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"] # TODO: tighten to specific ips?
    self = false
    security_group_ids = null
  }]
}

# ==============================================================
# s3 Bucket
# ==============================================================
module "benchmarks_bucket" {
  source            = "./modules/s3/bucket"
  count             = local.all_environments
  bucket_name       = var.benchmarks_bucket
  bucket_acl        = "private"
  enable_versioning = false
  expiration_settings = [{
    prefix = "benchmarks/1Day/"
    days   = 90
  }]
}
module "benchmarks_bucket_policy" {
  source    = "./modules/s3/policy"
  count     = local.only_harvard
  bucket_id = module.benchmarks_bucket[0].bucket_id
  # give washu account access to benchmarks bucket
  policy = <<POLICY
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "washu permissions",
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::${module.peer_account_info[0].secret_json["account_number"]}:root"
         },
         "Action": [
            "s3:GetBucketLocation",
            "s3:ListBucket"
         ],
         "Resource": [
            "arn:aws:s3:::${var.benchmarks_bucket}"
         ]
      },
      {
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::${module.peer_account_info[0].secret_json["account_number"]}:root"
         },
         "Action": [
            "s3:GetObject"
         ],
         "Resource": [
            "arn:aws:s3:::${var.benchmarks_bucket}/*"
         ]
      }
   ]
}
POLICY
}

# ==============================================================
# benchmark items
# ==============================================================
module "benchmarks_ecr_repository" { # could potentially make public to save on cost
  source          = "./modules/ecr"
  count           = local.all_environments
  repository_name = "${var.benchmarks_name_prefix}-repository"
}
module "github_service_user" {
  source             = "./modules/iam/user"
  count              = local.only_harvard
  name               = "${var.benchmarks_name_prefix}-github-user"
  permitted_services = "\"states:*\""
}

module "batch_benchmark_artifacts" {
  source                    = "./modules/benchmarks"
  count                     = local.all_environments
  name_prefix               = var.benchmarks_name_prefix
  instance_types            = ["optimal"]
  timeout_seconds           = 86400                                                          # 24 hour timeout for jobs
  docker_image              = "${module.benchmarks_ecr_repository[0].repository_url}:test-image" # TODO - use version tag
  container_cpu             = 48
  container_memory          = 98304
  container_properties_file = "../../modules/batch/container-properties/container-properties.json"
  region                    = data.aws_region.current.name
  log_retention_days        = 5
  s3_path                   = "s3://${var.benchmarks_bucket}"
  ec2_key_pair              = var.organization == "harvard" ? "lestrada_keypair" : null # used for debugging purposes
  volume_size               = 400
  shared_memory_size        = 10000
  resolution                = 24
  num_cores_per_node        = 6
  step_fn_definition_file   = "../../modules/step-function/state-machine-definitions/cloud-benchmarks.json"
  enable_step_function      = true
  use_default_vpc           = var.organization == "harvard" ? false : true
  peer_account_number       = module.peer_account_info[0].secret_json["account_number"]
  peer_security_group_id    = module.peer_account_info[0].secret_json["security_group_id"]
  peering_connection_id     = var.organization == "harvard" ? module.vpc_peering_connection_with_washu[0].connection_id : null
  # harvard stores the fsx ip address in secrets manager
  fsx_address               = (var.organization == "harvard"
                                ? module.peer_account_info[0].secret_json["fsx_ip_address"] 
                                : module.fsx_lustre_instance[0].fsx_dns)
}

# ==============================================================
# data volume
# ==============================================================
module "fsx_lustre_instance" {
  source = "./modules/fsx-lustre"
  count = local.only_washu
  subnet_ids = (var.organization == "harvard" 
    ? tolist(module.batch_benchmark_artifacts[0].subnet_ids)[0] 
    : tolist(module.batch_benchmark_artifacts[0].subnet_ids)[1]) # subnet AZ us-east-1e does not have fsx support
  security_group_ids = [module.batch_benchmark_artifacts[0].security_group_id]
}

# ==============================================================
# input data sync items
# ==============================================================
module "batch_data_sync_artifacts" {
  source                    = "./modules/batch"
  count                     = local.all_environments
  name_prefix               = "bashdatacatalog-input-data-sync"
  subnet_ids                = module.batch_benchmark_artifacts[0].subnet_ids
  ami_id                    = null # currently using default ami
  instance_types            = ["optimal"]
  security_group_id         = module.batch_benchmark_artifacts[0].security_group_id
  timeout_seconds           = 86400                                                         # 24 hour timeout for jobs
  docker_image              = "${module.benchmarks_ecr_repository[0].repository_url}:test-image" # TODO - use version tag
  container_cpu             = 1
  container_memory          = 2000
  container_properties_file = "../../modules/batch/container-properties/container-properties.json"
  region                    = data.aws_region.current.name
  log_retention_days        = 30
  volume_size               = 30
  compute_type              = "EC2"
  default_command           = "./scripts/utils/update-bashdatacatalog.sh"
  launch_script_path        = "../../modules/batch/launch-scripts/fsx-mount-script.sh"
  ec2_key_pair              = var.organization == "harvard" ? "lestrada_keypair" : null # used for debugging purposes
  fsx_address               = (var.organization == "harvard"
                                ? module.peer_account_info[0].secret_json["fsx_ip_address"] 
                                : module.fsx_lustre_instance[0].fsx_dns)
  compute_resource_tags = {
    Name = "bashdatacatalog-input-data-sync"
  }
}

module "input_data_sync_trigger" {
  source               = "./modules/cloudwatch/events"
  count                = local.all_environments
  name_prefix          = "bashdatacatalog-input-data-sync-rule"
  description          = "rule that triggers daily input data sync batch job"
  target_arn           = module.batch_data_sync_artifacts[0].batch_job_queue_arn
  schedule_expression  = "cron(0 10 * * ? *)" # every day at 10 am
  batch_job_definition =  module.batch_data_sync_artifacts[0].batch_job_definition_name
  is_enabled = false
}

# ==============================================================
# image builder items
# ==============================================================
module "gchp_image_builder" {
  source             = "./modules/ec2-image-builder"
  count              = local.all_environments
  component_name     = "InstallSpackEnvironment"
  name_prefix        = "spackenv"
  component_platform = "Linux"
  builder_version    = "1.0.2" # TODO: figure out a way to stop needing to change this with every update 
  component_file     = "../../modules/ec2-image-builder/components/install-spack-component.yaml"
  security_group_id  = module.default_security_group[0].security_group_id
  subnet_id          = tolist(data.aws_subnet_ids.all_default_subnets.ids)[0]
  recipe_name        = "geoschem_deps-pcluster_ami-x86_64-alinux2-intel_latest-intelmpi_latest"
}

# ==============================================================
# AQACF items
# ==============================================================
module "AQACF_bucket" {
  source            = "./modules/s3/bucket"
  count             = local.only_washu
  bucket_name       = "${var.organization}-aqacf-data"
  enable_versioning = false
  bucket_policy     = <<POLICY
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "AQACF permissions",
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::${module.AQACF_account_number[0].secret_json["account_number"]}:root"
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
            "AWS": "arn:aws:iam::${module.AQACF_account_number[0].secret_json["account_number"]}:root"
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
  source         = "./modules/sns"
  count          = local.all_environments
  sns_topic_name = "gcst-sns-topic"
}
module "cloudwatch_cost_alarm" {
  source           = "./modules/cloudwatch/alarms"
  count            = local.all_environments
  alarm_name       = "account-billing-alarm"
  metric_name      = "EstimatedCharges"
  metric_namespace = "AWS/Billing"
  currency         = "USD"
  threshold        = "450"
  description      = "This metric monitors total estimated monthly costs"
  sns_topic_arn    = module.gcst_sns_topic[0].arn
  account_number   = data.aws_caller_identity.current.account_id
}

# ==============================================================
# secret items
# ==============================================================
module "peer_account_info" { # fetch the account info of peer account
  source     = "./modules/secrets-manager"
  count      = local.all_environments
  secret_arn = (
    var.organization == "harvard" 
    ? "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:washu_account_info-t14Lkb" 
    : "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:harvard_account_info-IsgZ0t"
  )
}
module "AQACF_account_number" {
  source     = "./modules/secrets-manager"
  count      = local.only_washu
  secret_arn = "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:aqacf_account_number-KhNkAJ"
}

# ==============================================================
# vpc peering connection
# ==============================================================
module "vpc_peering_connection_with_washu" {
   source = "./modules/vpc/peering"
   count = local.only_harvard
   peer_account_id = module.peer_account_info[0].secret_json["account_number"]
   peer_vpc_id = module.peer_account_info[0].secret_json["vpc_id"]
   requester_vpc_id = module.batch_benchmark_artifacts[0].vpc_id
   tags = { Name = "washu-harvard-vpc-peering" }
}
