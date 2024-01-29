module "tmp_001" {
  source = "../lambda_function_basic"

  function_identifier = "tmp_001"
  handler             = "index.handler"
  memory_size         = 128
  layers = [data.aws_ssm_parameter.base_layer_arn.value]

  system_name = var.system_name
  role_arn    = aws_iam_role.tmp.arn
  region      = var.region
}