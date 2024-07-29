variable "model_ecr_image" {
  type = string
  description = "URI to ECR holding model image to serve"
}

variable "model_uri" {
  type = string
  description = "URI to MLFlow model"
}

variable "ec2_instance_type" {
  description = "Name of EC2 instance type"
  type = string
}
