resource "aws_dynamodb_table" "table" {
    name = var.table_name
    billing_mode = var.billing_mode
    hash_key = var.hash_key

    dynamic "attribute" {
        for_each = [for a in var.attributes: {
            name = a.name
            type = a.type
        }]

        content {
            name = attribute.value.name
            type = attribute.value.type
        }
    }
}