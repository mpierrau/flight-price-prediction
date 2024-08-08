terraform {
    required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
  backend "s3" {
    bucket = "mpierrau-tf-state-flight-price-prediction"
    key = "flight-price-prediction-sagemaker.tfstate"
    region = "us-east-1"
    encrypt = true
  }
  required_version = ">= 1.8"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "model_repo" {
  name = "${var.model_ecr_image}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# SSM parameter setup by mlflow infra
data "aws_ssm_parameter" "mlflow_bucket_url" {
  name  = "/mlflow-tf/${var.env}/ARTIFACT_URL"
}

locals {
  mlflow_model_uri = "${data.aws_ssm_parameter.mlflow_bucket_url.value}/${var.model_id}/artifacts/model/"
}

resource "aws_sagemaker_model" "sagemaker_model" {
  name = "${var.model_name}-model-${var.env}"
  execution_role_arn = aws_iam_role.sagemaker_role.arn
  primary_container {
    image = "${aws_ecr_repository.model_repo.name}:${var.ecr_image_tag}"
    mode = "SingleModel"
    environment = tomap(
      {
        MLFLOW_MODEL_URI = local.mlflow_model_uri
      }
    )
    image_config {
      repository_access_mode = "Platform"
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_config" {
  name = "${var.model_name}-endpoint-config-${var.env}"
  production_variants {
    variant_name = "variant-1"
    model_name = aws_sagemaker_model.sagemaker_model.name
    initial_instance_count = 1
    instance_type = var.ec2_instance_type
    initial_variant_weight = 1.0
  }
}

resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name = "${var.model_name}-endpoint-${var.env}"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config.name
}
