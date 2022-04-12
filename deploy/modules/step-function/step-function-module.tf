resource "aws_sfn_state_machine" "state_machine" {
  name = "${var.name}-workflow"
  role_arn = aws_iam_role.default_sfn_role.arn
  definition = data.template_file.state_machine_definition.rendered
}

data "template_file" "state_machine_definition" {
  template = file(var.definition_file)
  vars = var.state_machine_definition_vars
}