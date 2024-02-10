data "aws_ssm_parameter" "base_layer_arn" {
  name = "/LuciferousHidemyNameProxy/Layer/Base"
}

resource "aws_ssm_parameter" "code_hidemy_name_proxy" {
  name  = "CODE_HIDEMY_NAME_PROXY"
  type  = "SecureString"
  value = var.code_hidemy_name_proxy
}
