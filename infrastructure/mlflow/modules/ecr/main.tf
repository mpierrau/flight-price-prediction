# Make sure to create state bucket beforehand
terraform {
  required_version = ">= 1.8"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.61.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = ">= 3.0.0"
    }
  }
}

resource "aws_ecr_repository" "mlflow_ecr" {
  name                 = "${var.app_name}-${var.env}-image"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}


data "aws_ecr_authorization_token" "token" {}
data "aws_caller_identity" "current_identity" {}
locals {
  account_id = data.aws_caller_identity.current_identity.account_id
}

provider "docker" {
  registry_auth {
    address  = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

locals {
  watchfiles = ["Dockerfile", "pyproject.toml", "entrypoint.sh", "mlflow_auth.py"]
  monitor_dir = "${path.root}/${var.src_dir}"
  trigger_hash = md5(join("", [for f in local.watchfiles : filesha1("${local.monitor_dir}/${f}")]))
}

resource "docker_image" "this" {
  name = "${aws_ecr_repository.mlflow_ecr.repository_url}:${var.ecr_image_tag}"

  build {
    context = "${path.cwd}/${var.src_dir}"
  }
  # Watch for changes in .py files and local.watchfiles.
  triggers = {
    watchfiles_md5 = local.trigger_hash
  }
}

# push image to ecr repo
resource "docker_registry_image" "this" {
  depends_on = [ aws_ecr_repository.mlflow_ecr, docker_image.this ]
  name       = docker_image.this.name
  keep_remotely = false

  triggers = {
    watchfiles_md5 = local.trigger_hash
  }
}

# Wait for the image to be uploaded before lambda config runs
data "aws_ecr_image" "mlflow_image" {
  depends_on = [
    docker_registry_image.this
   ]
   repository_name = aws_ecr_repository.mlflow_ecr.name
   image_tag = var.ecr_image_tag
}
