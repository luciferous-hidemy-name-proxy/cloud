resource "aws_sqs_queue" "check_proxy_checker" {
  name_prefix                = "check_proxy_checker_"
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue" "check_proxy_closer" {
  name_prefix                = "check_proxy_closer_"
  visibility_timeout_seconds = 30
}
