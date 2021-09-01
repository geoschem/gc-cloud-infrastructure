variable table_name {
	description = "Must be a unique name for the dynamo table"
}

variable billing_mode {
    description = "Controls how you are charged for read and write throughput and how you manage capacity. The valid values are PROVISIONED and PAY_PER_REQUEST"
}

variable hash_key {
    description = "The attribute to use as the hash (partition) key. Must also be defined as an attribute, see below"
}

variable attributes {
    description = "List of nested attribute definitions. Only required for hash_key and range_key attributes. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table#attribute"
    type = list(object({
        name = string
        type = string
    }))
}