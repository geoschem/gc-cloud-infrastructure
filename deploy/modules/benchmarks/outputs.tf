output "vpc_id" {
  value = local.vpc_id
}
output "security_group_id" {
  value = module.benchmarks_security_group.security_group_id
}
output "subnet_ids" {
  value = data.aws_subnets.subnets.ids
}
