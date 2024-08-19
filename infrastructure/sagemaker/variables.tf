variable "aws_region" {
  description = "AWS region to create resources"
  type = string
}

variable "project_id" {
  description = "Identifier prefix for project resources"
  type = string
}
variable "model_ecr_image_prefix" {
  description = "URI to ECR holding model image to serve"
  type = string
}

variable "ecr_image_tag" {
  description = "ECR image tag to use"
  type = string
}

variable "ec2_instance_type" {
  description = "Name of EC2 instance type"
  type = string
}

variable "model_id" {
  description = "MLFlow model ID, {Experiment ID}/{Run ID}"
  type = string
}

variable "env" {
  description = "Set variable depending on environemnt - appended to resources."
  type = string
}

variable "src_dir" {
  description = "Directory with source code. Used to monitor for changes."
  type = string
}

variable "alarm_subscribers" {
  description = "Email adresses for all subscribers to the Sagemaker Cloudwatch alarms."
  type = list(string)
}
