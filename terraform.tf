terraform {
  backend "s3" {
    bucket = "luciferous-hidemy-name-prox-bucketterraformstates-1r2mrb5ix8t4q"
    key    = "cloud/state.tfstate"
    region = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      SystemName = local.system_name
    }
  }
}

module "common" {
  source = "./terraform_modules/common"

  system_name            = local.system_name
  region                 = local.region
  code_hidemy_name_proxy = var.CODE_HYDEMY_NAME_PROXY
  my_api_secret          = var.MY_API_SECRET
  slack_incoming_webhooks = [
    var.SLACK_INCOMING_WEBHOOK_1ST,
    var.SLACK_INCOMING_WEBHOOK_2ND,
  ]
}

locals {
  region      = "ap-northeast-1"
  system_name = "hidemy-name-proxy-cloud"
}

variable "CODE_HYDEMY_NAME_PROXY" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "SLACK_INCOMING_WEBHOOK_1ST" {
  type     = string
  nullable = false
}

variable "SLACK_INCOMING_WEBHOOK_2ND" {
  type     = string
  nullable = false
}

variable "MY_API_SECRET" {
  type     = string
  nullable = false
}

output "sns_topic_error_notificator" {
  value = module.common.sns_topic_error_notificator
}

output "api_root" {
  value = module.common.api_root
}

output "api_all" {
  value = module.common.api_all
}

output "api_random" {
  value = module.common.api_random
}