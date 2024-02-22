resource "aws_cloudwatch_metric_alarm" "error_notificator" {
  alarm_name          = module.error_notificator.function_name
  alarm_actions       = [aws_sns_topic.root_error_notifier.arn]
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  dimensions = {
    FunctionName = module.error_notificator.function_name
  }
  metric_name        = "Errors"
  namespace          = "AWS/Lambda"
  period             = 60
  statistic          = "Sum"
  treat_missing_data = "notBreaching"
}
