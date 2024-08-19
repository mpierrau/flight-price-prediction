# Make sure to create state bucket beforehand
terraform {
  required_version = ">= 1.8"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
  backend "s3" {
    bucket = "tf-state-flight-price-prediction-mpierrau"
    key = "flight-price-prediction-monitoring.tfstate"
    region = "eu-north-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# Report bucket
resource "aws_s3_bucket" "report_bucket" {
  bucket = "${var.report_bucket_name}-${var.project_id}-${var.env}"
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.reference_data_bucket_name}-${var.project_id}-${var.env}"
}

module "ecr_image" {
  source = "./modules/ecr"
  region = var.aws_region
  ecr_repo_name = "${var.ecr_repo_name}-${var.project_id}-${var.env}"
  ecr_image_tag = var.ecr_image_tag
  src_dir = var.src_dir
}

module "lambda_function" {
  source = "./modules/lambda"
  report_bucket = aws_s3_bucket.report_bucket.bucket
  lambda_function_name = "${var.lambda_function_name}-${var.project_id}-${var.env}"
  image_uri = "${module.ecr_image.image_uri}"
  mlflow_run_id = var.mlflow_run_id
  monitoring_data_bucket = aws_s3_bucket.data_bucket.bucket
  mlflow_model_bucket = var.mlflow_model_bucket
}
