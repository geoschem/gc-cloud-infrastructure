variable "peer_account_id" {
    description = "account id of the vpc you are trying to connect to"
}
variable "peer_vpc_id" {
    description = "vpc id of the vpc you are trying to connect to"
}
variable "requester_vpc_id" {
    description = "vpc id you'd like to peer with for this account (the requester)"
}
variable "peer_region" {
    description = "region of the vpc you are peering with"
    default = "us-east-1"
}
variable "tags" {
    description = "tags for your vpc peering connection"
    default = null
}