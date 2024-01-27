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

  system_name = local.system_name
  region      = local.region
}

locals {
  region      = "ap-northeast-1"
  system_name = "hidemy-name-proxy-cloud"
}