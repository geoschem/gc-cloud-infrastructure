variable "cidr_block" {
    description = "cidr block for the vpc (eg. 10.0.0.0/16)"
}
variable "availability_zone" {
    description = "vailability zone"
}
variable "vpc_id" {
    description = "vpc id for subnet"
}
variable "name" {
    description = "name for subnet"
}
variable "route_table_id" {
    description = "id of route table"
}