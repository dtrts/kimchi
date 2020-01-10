module "core" {
  source     = "../modules/core"
  localstack = "false"
}

provider "aws" {
  profile = "aws"
  region  = "eu-west-2"
}
