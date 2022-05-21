variable "name_prefix" {
  description = "name prefix used for lambda function and related resources"
}
variable "handler" {
  description = "entrypoint for the lambda function"
}
variable "code_path" {
  description = "path to source code dir"
}
variable "runtime" {
  description = "lambda function runtime (eg. python3.9)"
  default     = "python3.9"
}
variable "packages_path" {
  description = "path to python packages needed to run code (remember to package it)"
}
variable "enable_lambda_function_url" {
  description = "whether to create lambda function url"
  default     = false
}
variable "allow_methods" {
  description = "which api methods to allow (eg. [GET, POST, DELETE])"
  default     = ["GET"]
}
variable "function_url_authentication" {
  description = "type of authentication needed to access lambda url"
  default     = "NONE"
}
variable "additional_role_permissions" {
  description = "list of arns for additional permission policies function needs"
  default     = []
}
variable "log_expiration_days" {
  description = "number of days logs expire in"
  default     = 14
}
