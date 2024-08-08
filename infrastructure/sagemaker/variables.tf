variable "aws_region" {
    description = "AWS region to create resources"
    default = "eu-north-1"
}

variable "model_ecr_image" {
  type = string
  description = "URI to ECR holding model image to serve"
}

variable "ecr_image_tag" {
  type = string
  description = "ECR image tag to use"
}

variable "ec2_instance_type" {
  description = "Name of EC2 instance type"
  type = string
}

variable "model_id" {
  description = "MLFlow model ID, {Experiment ID}/{Run ID}"
  type = string
}

variable "model_name" {
  description = "Name of the Sagemaker model and related resources."
  type = string
  default = "flight-price-prediction"
}

variable "env" {
  description = "Set variable depending on environemnt - appended to resources."
  type = string
  default = "stg"
}
