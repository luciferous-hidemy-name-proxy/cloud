terraform {
  backend "s3" {
    bucket = "luciferous-hidemy-name-prox-bucketterraformstates-1r2mrb5ix8t4q"
    key    = "cloud/state.tfstate"
  }
}

module "common" {
  source = "./terraform_modules/common"
}
