module "core" {
  source     = "../modules/core"
  localstack = "false"
}

provider "aws" {
  profile = "dtrts"
  region  = "eu-west-2"
}
