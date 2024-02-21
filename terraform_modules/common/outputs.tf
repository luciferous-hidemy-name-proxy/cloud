output "sns_topic_error_notificator" {
  value = aws_sns_topic.root_error_notifier.name
}