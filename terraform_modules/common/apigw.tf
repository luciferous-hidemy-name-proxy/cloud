locals {
  apigw = {
    path = {
      all    = "all.json"
      random = "random.json"
    }
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = "api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

module "api_lambda_api_all" {
  source = "../http_api_lambda_route"

  api_id      = aws_apigatewayv2_api.api.id
  lambda_arn  = module.api_all.function_alias_arn
  http_method = "GET"
  path        = local.apigw.path.all
}

module "api_lambda_api_random" {
  source = "../http_api_lambda_route"

  api_id      = aws_apigatewayv2_api.api.id
  lambda_arn  = module.api_random.function_alias_arn
  http_method = "GET"
  path        = local.apigw.path.random
}