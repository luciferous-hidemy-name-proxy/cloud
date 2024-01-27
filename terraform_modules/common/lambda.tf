module "tmp_001" {
  source = "../lambda_function_basic"

  function_identifier = "tmp_001"
  handler             = "index.handler"
  memory_size         = 128

  system_name = var.system_name
  role_arn    = aws_iam_role.tmp.arn
  region      = var.region
}