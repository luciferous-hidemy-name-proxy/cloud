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

  environment_variables = {
    SSM_PARAMETER_NAME_CODE_HIDEMY_NAME = aws_ssm_parameter.code_hidemy_name_proxy.name
    TABLE_NAME_TEMP_STORE               = aws_dynamodb_table.temp_store.name
  }

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}

resource "aws_lambda_permission" "call_hidemy_name" {
  action        = "lambda:InvokeFunction"
  function_name = module.call_hidemy_name.function_name
  qualifier     = module.call_hidemy_name.function_alias_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.call_hidemy_name.arn
}

# ================================================================
# Lambda check_proxy_checker
# ================================================================

module "check_proxy_checker" {
  source = "../lambda_function"

  handler_dir_name = "check_proxy_checker"
  handler          = "check_proxy_checker.handler"
  memory_size      = 128
  timeout          = aws_sqs_queue.check_proxy_checker.visibility_timeout_seconds
  role_arn         = aws_iam_role.check_proxy.arn

  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn
  ]

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}

resource "aws_lambda_event_source_mapping" "check_proxy_checker" {
  event_source_arn = aws_sqs_queue.check_proxy_checker.arn
  function_name    = module.check_proxy_checker.function_alias_arn
  batch_size       = 1
  enabled          = true

  maximum_batching_window_in_seconds = aws_sqs_queue.check_proxy_checker.visibility_timeout_seconds
  scaling_config {
    maximum_concurrency = 100
  }
}

# ================================================================
# Lambda check_proxy_closer
# ================================================================

module "check_proxy_closer" {
  source = "../lambda_function"

  handler_dir_name = "check_proxy_closer"
  handler          = "check_proxy_closer.handler"
  memory_size      = 128
  timeout          = aws_sqs_queue.check_proxy_closer.visibility_timeout_seconds
  role_arn         = aws_iam_role.check_proxy.arn

  reserved_concurrent_executions = 1

  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn
  ]

  environment_variables = {
    S3_BUCKET      = aws_s3_bucket.data.bucket
    S3_KEY         = local.s3.data_key
    DYNAMODB_TABLE = aws_dynamodb_table.temp_store.name
    SQS_QUEUE_URL  = aws_sqs_queue.check_proxy_checker.url
  }

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}

resource "aws_lambda_event_source_mapping" "check_proxy_closer" {
  event_source_arn = aws_sqs_queue.check_proxy_closer.arn
  function_name    = module.check_proxy_closer.function_alias_arn
  batch_size       = 10
  enabled          = true

  maximum_batching_window_in_seconds = aws_sqs_queue.check_proxy_closer.visibility_timeout_seconds
}

# ================================================================
# Lambda api_all
# ================================================================

module "api_all" {
  source = "../lambda_function"

  handler_dir_name = "api_all"
  handler          = "api_all.handler"
  memory_size      = 128
  timeout          = 29
  role_arn         = aws_iam_role.api_lambda

  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn,
  ]

  environment_variables = {
    S3_BUCKET = aws_s3_bucket.data.bucket
    S3_KEY    = local.s3.data_key
  }

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}

resource "aws_lambda_permission" "api_all" {
  action        = "lambda:InvokeFunction"
  function_name = module.api_all.function_name
  qualifier     = module.api_all.function_alias_name
  principal     = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

# ================================================================
# Lambda api_random
# ================================================================

module "api_random" {
  source = "../lambda_function"

  handler_dir_name = "api_random"
  handler          = "api_random.handler"
  memory_size      = 128
  timeout          = 29
  role_arn         = aws_iam_role.api_lambda

  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn,
  ]

  environment_variables = {
    S3_BUCKET = aws_s3_bucket.data.bucket
    S3_KEY    = local.s3.data_key
  }

  system_name                         = var.system_name
  region                              = var.region
  subscription_destination_lambda_arn = module.error_notificator.function_arn
}

resource "aws_lambda_permission" "api_random" {
  action        = "lambda:InvokeFunction"
  function_name = module.api_random.function_name
  qualifier     = module.api_random.function_alias_name
  principal     = "${aws_apigatewayv2_api.api.execution_arn}/*"
}
