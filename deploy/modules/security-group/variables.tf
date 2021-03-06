variable vpc_id {
    description = "vpc that will house the security group"
}

variable name {
    description = "name for security group"
}

variable description {
    description = "description for security group"
}
variable ingress_rules {
    description = "list of ingress rules for security group"
}
