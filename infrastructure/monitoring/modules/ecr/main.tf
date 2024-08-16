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

resource "aws_ecr_repository" "monitor_repo" {
  name = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

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
  watchfiles = ["Dockerfile", "pyproject.toml", "poetry.lock"]
  monitor_dir = "${path.root}/${var.src_dir}"
}

resource "docker_image" "this" {
  name = "${aws_ecr_repository.monitor_repo.repository_url}:${var.ecr_image_tag}"

  build {
    context = "${path.cwd}/${var.src_dir}"
  }
  # Watch for changes in .py files and local.watchfiles.
  triggers = {
    pydir_md5    = md5(join("", [for f in fileset(local.monitor_dir, "**/*.py") : filesha1("${local.monitor_dir}/${f}")]))
    watchfiles_md5 = md5(join("", [for f in local.watchfiles : filesha1("${local.monitor_dir}/${f}")]))
  }
}

# push image to ecr repo
resource "docker_registry_image" "this" {
  depends_on = [ aws_ecr_repository.monitor_repo, docker_image.this ]
  name       = docker_image.this.name
  keep_remotely = true

  triggers = {
    pydir_md5    = md5(join("", [for f in fileset(local.monitor_dir, "**/*.py") : filesha1("${local.monitor_dir}/${f}")]))
    watchfiles_md5 = md5(join("", [for f in local.watchfiles : filesha1("${local.monitor_dir}/${f}")]))
  }
}

# Wait for the image to be uploaded before lambda config runs
data "aws_ecr_image" "lambda_image" {
  depends_on = [
    docker_registry_image.this
   ]
   repository_name = var.ecr_repo_name
   image_tag = var.ecr_image_tag
}
