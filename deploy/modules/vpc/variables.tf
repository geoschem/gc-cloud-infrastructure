variable "cidr_block" {
  description = "cidr block for the vpc (eg. 10.0.0.0/16)"
}
variable "public_subnets_info" {
  description = "list of availability zones and cidr blocks for public subnets"
}
variable "name_prefix" {
  description = "name prefix for vpc items"
}
variable "peering_connection_id" {
  description = "id for peering connection rule"
}
