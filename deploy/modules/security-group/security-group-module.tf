resource "aws_security_group" "security_group" {
    name = var.name
    description = var.description
    vpc_id = var.vpc_id

    ingress { #ssh rule
        protocol = "tcp"
        from_port = 22
        to_port = 22
        cidr_blocks = var.ingress_cidr_blocks
    }

    # allow all outbound traffic
    egress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}
