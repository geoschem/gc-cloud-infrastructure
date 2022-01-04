resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = var.evaluation_period
  metric_name = var.metric_name
  namespace = var.metric_namespace
  datapoints_to_alarm = "1"
  period = var.period
  statistic = var.statistic
  threshold = var.threshold
  alarm_description = var.description
  alarm_actions = [var.sns_topic_arn]
  dimensions = {
    Currency      = "USD"
  }
}
