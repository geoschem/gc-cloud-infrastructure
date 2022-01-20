resource "aws_security_group" "security_group" {
    name = var.name
    description = var.description
    vpc_id = var.vpc_id
    dynamic "ingress" {
        for_each = var.ingress_rules
        content {
            protocol = ingress.value["protocol"]
            from_port = ingress.value["from_port"]
            to_port = ingress.value["to_port"]
            cidr_blocks = ingress.value["cidr_blocks"]
            self = ingress.value["self"]
            security_groups = ingress.value["security_group_ids"]
            description = ""
        }
    }

    # allow all outbound traffic
    egress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}
