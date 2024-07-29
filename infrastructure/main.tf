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

module "ecr_image" {
  source = "./modules/ecr"
  ecr_repo_name = "${var.ecr_repo_name}_${var.project_id}"
  account_id = local.account_id
  docker_image_local_path = var.docker_image_local_path
  ecr_image_tag = var.ecr_image_tag
  region = var.aws_region
}

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = "${var.model_bucket_name}-${var.project_id}"
}

# module "ec2" {
#   source = "./modules/ec2"
#   account_id = local.account_id
#   api_port = 8080
#   ssh_port = 22
#   aws_region = var.aws_region
#   docker_image = module.ecr_image.image_uri
#   ec2_instance_type = var.ec2_instance_type
#   model_uri = "s3://${var.model_bucket_name}/${var.model_uri}/artifacts/model/"
# }

# output "ec2_public_ip" {
#   value = module.ec2.ip
# }


module "sagemaker" {
  source = "./modules/sagemaker"
  model_ecr_image = module.ecr_image.image_uri
  ec2_instance_type = var.ec2_instance_type
  model_uri = "s3://${var.model_bucket_name}/${var.model_id}/artifacts/model/"
}
