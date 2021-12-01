variable "name" {
  description = "name for this step function (state machine)"
}

variable "definition_file" {
  description = "file location which contains the json data that defines the workflow for this state machine"
}

variable "state_machine_definition_vars" {
  description = "an object containing key value pairs of variables to be replaced within the workflow definition"
}
