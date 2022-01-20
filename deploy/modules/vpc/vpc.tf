resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name_prefix}-internet-gateway"
  }
}
resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    cidr_block = "172.31.0.0/16"
    vpc_peering_connection_id = "pcx-0fca1c99657518420"
  }

  tags = {
    Name = "${var.name_prefix}-route-table"
  }
}

module subnets {
    source = "./subnet"
    count = length(var.public_subnets_info)

    availability_zone = var.public_subnets_info[count.index].availability_zone
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnets_info[count.index].cidr_block
    name = "public-subnet-${count.index+1}"
    route_table_id = aws_default_route_table.route_table.id
}
