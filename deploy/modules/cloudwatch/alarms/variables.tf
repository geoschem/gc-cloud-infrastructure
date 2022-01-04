variable alarm_name {
  description = "name of alarm"
}
variable metric_name {
  description = "name of metric to track (eg. EstimatedCharges)"
}
variable metric_namespace {
  description = "namespace of the metric you'd like to track (eg. AWS/Billing)"
}
variable statistic {
  description = "The statistic to apply to the alarm's associated metric (eg. Maximum)"
  default = "Maximum"
}
variable evaluation_period {
  description = "number of periods the statistic is applied over (eg. 1)"
  default = "1"
}
variable period {
  description = "number of seconds in a given measurement period"
  default = "21600"
}
variable currency {
  description = "unit of measurement for metric (eg. USD)"
  default = null
}
variable threshold {
  description = "threshold to trigger alarm if exceeded (eg. 400)"
}
variable description {
  description = "description of alarm"
  default = null
}
variable sns_topic_arn {
  description = "arn of sns list notifications will be sent to"
}
variable account_number {
  description = "arn of sns list notifications will be sent to"
}