data "archive_file" "common_layer" {
  type        = "zip"
  output_path = "layer_common.zip"
  source_dir  = "${path.root}/src/common"
}

resource "aws_lambda_layer_version" "common" {
  layer_name = "layer-common"

  filename         = data.archive_file.common_layer.output_path
  source_code_hash = data.archive_file.common_layer.output_base64sha256
}


module "tmp_001" {
  source = "../lambda_function_basic"

  function_identifier = "tmp_001"
  handler             = "index.handler"
  memory_size         = 128
  layers = [
    data.aws_ssm_parameter.base_layer_arn.value,
    aws_lambda_layer_version.common.arn
  ]
  environment_variables = {
    PROXY_HOST = "185.231.115.246"
    PROXY_PORT = "7237"
  }

  system_name = var.system_name
  role_arn    = aws_iam_role.tmp.arn
  region      = var.region
}