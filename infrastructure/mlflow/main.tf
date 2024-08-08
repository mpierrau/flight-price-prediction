terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
  backend "s3" {
    bucket = "mpierrau-tf-state-flight-price-prediction"
    key = "flight-price-prediction-mlflow.tfstate"
    region = "us-east-1"
    encrypt = true
  }
  required_version = ">= 1.8"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# S3 bucket for holding MLFlow artifacts
module "s3" {
  source = "./modules/s3"
  app_name = var.app_name
  env = var.env
}

# IAM for permission roles
module "iam" {
  source = "./modules/iam"
  app_name = var.app_name
  env = var.env
}

# ECR for holding MLFlow Docker container
module "ecr" {
  source = "./modules/ecr"
  app_name = var.app_name
  env = var.env
}

# Network settings for security and connectivity
module "network" {
  source = "./modules/network"
  app_name = var.app_name
  cidr = var.cidr
  private_cidr_a = var.private_cidr_a
  private_cidr_b = var.private_cidr_b
  public_cidr_a = var.public_cidr_a
  public_cidr_b = var.public_cidr_b
  db_cidr_a = var.db_cidr_a
  db_cidr_b = var.db_cidr_b
  zone_a = var.zone_a
  zone_b = var.zone_b
  env = var.env
  internet_cidr = var.internet_cidr
  your_vpn = var.your_vpn
}

# RDS for DB to hold MLFlow data
module "rds" {
  source = "./modules/rds"
  app_name = var.app_name
  db_subnet_group_name = module.network.db_subnet_group_name
  db_security_groups = [
    module.network.security_group_allow_ingress_from_vpn.id,
    module.network.security_group_rds.id
  ]
  db_allocated_storage = var.db_allocated_storage
  db_engine = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
  env = var.env

  depends_on = [ module.network.main_gateway ]
}

# ECS for running the actual mlflow task
module "ecs" {
  source = "./modules/ecs"
  region = var.aws_region
  env = var.env
  ecs_task_name = var.ecs_task_name
  ecs_service_name = var.ecs_service_name
  ecs_mlflow_role_arn = module.iam.ecs_mlflow_role_arn
  app_name = var.app_name
  lb_target_group_arn = module.network.mlflow_lb_target_group_arn
  ecs_sg_id = module.network.ecs_security_group_id
  rds_sg_id = module.network.security_group_rds.id
  private_subnet_a_id = module.network.private_subnet_a_id
  private_subnet_b_id = module.network.private_subnet_b_id
  mlflow_ecr_repo_url = module.ecr.mlflow_ecr_repo_url

  # Need to wait for LB and DB URL in SSM to be ready
  depends_on = [
    module.network.mlflow_alb_listener,
    module.network.mlflow_aws_lb,
    module.network.mlflow_lb_listener_rule,
    module.network.mlflow_lb_target_group_arn,
    module.rds.db_url
  ]
}
