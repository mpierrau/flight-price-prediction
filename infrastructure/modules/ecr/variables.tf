variable "ecr_repo_name" {
  type = string
  description = "ECR repo name"
}

variable "docker_image_local_path" {
  description = "Path to Dockerfile"
}

variable "region" {
  type = string
  description = "AWS region to use"
  default = "us-east-1"
}

variable "ecr_image_tag" {
  description = "Docker image tag to use"
}

variable "account_id" {
}
