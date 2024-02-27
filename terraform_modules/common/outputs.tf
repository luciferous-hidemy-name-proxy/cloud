output "sns_topic_error_notificator" {
  value = aws_sns_topic.root_error_notifier.name
}

output "api_root" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "api_all" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${local.apigw.path.all}"
}

output "api_random" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${local.apigw.path.random}"
}