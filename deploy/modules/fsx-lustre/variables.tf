variable subnet_ids {
    description = "subnet ids needed for the fsx file system"
}
variable security_group_ids {
    description = "list of security groups to associate with the eni"
}
variable import_path {
    description = "s3 bucket path to import data from (optional)"
    default = null
}
