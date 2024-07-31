# Make sure to create state bucket beforehand
terraform {
  required_version = ">= 1.8"
  backend "s3" {
    bucket = "mpierrau-tf-state-flight-price-prediction"
    key = "flight-price-prediction.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current_identity" {}

locals {
  account_id = data.aws_caller_identity.current_identity.account_id
}

module "ecr" {
  source = "./modules/ecr"
  ecr_repo_name = "${var.ecr_repo_name}_${var.project_id}"
  account_id = local.account_id
  region = var.aws_region
}

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = "${var.model_bucket_name}-${var.project_id}"
}
