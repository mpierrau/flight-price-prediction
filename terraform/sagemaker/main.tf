terraform {
  required_version = ">= 1.8"
  backend "s3" {
    bucket = "mpierrau-tf-state-flight-price-prediction"
    key = "flight-price-prediction-sagemaker.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  mlflow_model_uri = "s3://${var.model_bucket_name}/${var.model_id}/artifacts/model/"
}

resource "aws_sagemaker_model" "sagemaker_model" {
  name = "${var.model_name}-model-${var.env}"
  execution_role_arn = aws_iam_role.sagemaker_role.arn
  primary_container {
    image = "${var.model_ecr_image}:${var.ecr_image_tag}"
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


# module "sagemaker" {
#   source = "./modules/sagemaker"
#   depends_on = [ module.ecr ]
#   model_ecr_image = module.ecr.ecr_repo_name_output
#   ec2_instance_type = var.ec2_instance_type
#   model_uri = "s3://${var.model_bucket_name}/${var.model_id}/artifacts/model/"
# }
