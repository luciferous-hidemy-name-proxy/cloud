resource "aws_apigatewayv2_integration" "integration" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = var.api_id
  route_key = "${var.http_method} /${var.path}"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}