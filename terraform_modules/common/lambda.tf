# ================================================================
# Layer Common
# ================================================================

data "archive_file" "common_layer" {
  type        = "zip"
  output_path = "layer_common.zip"
  source_dir  = "${path.root}/src/layers/common"
}

resource "aws_lambda_layer_version" "common" {
  layer_name = "layer-common"

  filename         = data.archive_file.common_layer.output_path
  source_code_hash = data.archive_file.common_layer.output_base64sha256
}

# ================================================================
# Lambda tmp_001
# ================================================================

module "tmp_001_v2" {
  source = "../lambda_function"

  handler_dir_name = "tmp_001"
  handler          = "index.handler"
  memory_size      = 128
  timeout          = 10
  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn
  ]
  environment_variables = {
    PROXY_HOST = "185.231.115.246"
    PROXY_PORT = "7237"
  }
  role_arn = aws_iam_role.tmp.arn

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}

# ================================================================
# Lambda Error Notificator
# ================================================================

module "error_notificator" {
  source = "../lambda_function_basic"

  handler_dir_name = "error_notificator"
  handler          = "error_notificator.handler"
  memory_size      = 256
  role_arn         = aws_iam_role.error_notificator.arn
  environment_variables = {
    EVENT_BUS_NAME = aws_cloudwatch_event_bus.slack_incoming_webhooks.name
    SYSTEM_NAME    = var.system_name
  }

  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn
  ]
  system_name = var.system_name
  region      = var.region
}

resource "aws_lambda_permission" "error_notificator" {
  action        = "lambda:InvokeFunction"
  function_name = module.error_notificator.function_arn
  principal     = "logs.amazonaws.com"
}

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

# ================================================================
# Lambda Call hidemy name
# ================================================================

module "call_hidemy_name" {
  source = "../lambda_function"

  handler_dir_name = "call_hidemy_name"
  handler          = "call_hidemy_name.handler"
  memory_size      = 128
  timeout          = 300
  role_arn         = aws_iam_role.call_hidemy_name.arn
  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn
  ]

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}