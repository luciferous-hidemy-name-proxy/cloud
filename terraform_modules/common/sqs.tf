resource "aws_sqs_queue" "check_proxy" {
  visibility_timeout_seconds = 300
}