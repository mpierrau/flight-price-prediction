variable "aws_region" {
    description = "AWS region to create resources"
    default = "eu-north-1"
}

variable "project_id" {
    description = "project_id"
    default = "mlops-zoomcamp"
}

variable "ecr_repo_name" {
    description = "Name of ECR repository"
}

variable "ecr_image_tag" {
    description = "Tag of ECR docker image"
}

variable "docker_image_local_path" {
    description = "Path to Dockerfile"
    type = string
}

variable "model_bucket_name" {
  description = "Name of S3 bucket with model artifacts"
  type = string
}

variable "ec2_instance_type" {
  description = "Type of EC2 instance to use"
  type = string
}

variable "model_id" {
  description = "MLFlow model ID, {Experiment ID}/{Run ID}"
  type = string
}
