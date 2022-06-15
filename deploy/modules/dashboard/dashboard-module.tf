module "dashboard_lambda" {
  source      = "../lambda"
  name_prefix = var.name_prefix
  handler     = "src.controller.handler"
  code_path   = "../../../dashboard/"
  packages_path  = "../../../dashboard/packages"
  enable_lambda_function_url = true
  additional_role_permissions = ["arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
  code_zip_exclude = fileset("../../../dashboard/", "packages/**")
}

module "user_registry_table" {
  source = "../dynamo"
  
  table_name = "geoschem_users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "EmailAddress"
  # only need indexed variables defined eg. primary key
  attributes = [
    {
      name = "EmailAddress"
      type = "S"
    }
  ]
}
