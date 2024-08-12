terraform {
    required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
  backend "s3" {
    bucket = "tf-state-flight-price-prediction-mpierrau"
    key = "flight-price-prediction-sagemaker.tfstate"
    region = "eu-north-1"
    encrypt = true
  }
  required_version = ">= 1.8"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current_identity" {}

# SSM parameter setup by mlflow infra
data "aws_ssm_parameter" "mlflow_bucket_url" {
  name  = "/mlflow-tf/${var.env}/ARTIFACT_URL"
}

locals {
  ecr_image = "${var.model_ecr_image_prefix}-${var.project_id}-${var.env}"
  mlflow_model_uri = "${data.aws_ssm_parameter.mlflow_bucket_url.value}/${var.model_id}/artifacts/model/"
}

resource "aws_ecr_repository" "model_repo" {
  name = local.ecr_image
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# Sets up all model endpoint resources
module "model" {
  source = "./modules/model"
  model_suffix = "${var.project_id}-${var.env}"
  model_image_url = "${aws_ecr_repository.model_repo.repository_url}:${var.ecr_image_tag}"
  mlflow_model_uri = local.mlflow_model_uri
  execution_role_arn = aws_iam_role.sagemaker_role.arn
  ec2_instance_type = var.ec2_instance_type
  endpoint_variant_name = "variant-1"
}

# SNS topic for sending alarm notifications by email/sms
resource "aws_sns_topic" "alarm_sns_topic" {
  name = "sagemaker_endpoint_alarms"
  display_name = "Sagemaker Alarm"
}

module "alarms" {
  source = "./modules/alarms"
  endpoint_name = module.model.sagemaker_endpoint_name
  variant_name = module.model.sagemaker_variant_name
  sns_topic_arn = aws_sns_topic.alarm_sns_topic.arn
}
