resource "aws_sqs_queue" "check_proxy_checker" {
  name_prefix = "check_proxy_checker"
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue" "check_proxy_closer" {
  name_prefix = "check_proxy_closer"
  visibility_timeout_seconds = 150
}

resource "aws_sqs_queue" "check_proxy_put_data" {
  name_prefix = "check_proxy_put_data"
  visibility_timeout_seconds = 150
}