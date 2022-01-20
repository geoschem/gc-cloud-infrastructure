resource "aws_vpc_peering_connection" "peering_connection" {
  peer_owner_id = var.peer_account_id
  peer_vpc_id   = var.peer_vpc_id
  vpc_id        = var.requester_vpc_id
  peer_region   = var.peer_region
  tags          = var.tags
  requester {
    allow_remote_vpc_dns_resolution = true
  }
}
