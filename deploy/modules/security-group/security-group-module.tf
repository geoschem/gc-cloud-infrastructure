resource "aws_security_group" "security_group" {
    name = var.name
    description = var.description
    vpc_id = var.vpc_id

    # TODO: tighten this up to just harvard ip
    ingress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    # allow all outbound traffic
    egress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}
