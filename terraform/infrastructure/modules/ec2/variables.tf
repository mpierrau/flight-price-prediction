variable "ssh_port" {
  description = "Port for SSH connections"
  type = number
  default = 22
}

variable "api_port" {
  description = "Port for API calls"
  type = number
  default = 8080
}

variable "aws_region" {
  description = "AWS region"
  type = string
  default = "eu-north-1"
}

variable "account_id" {
  type = string
}

variable "docker_image" {
  description = "Docker image to download and run on EC2 instance"
  type = string
}

variable "ec2_instance_type" {
  description = "Name of EC2 instance type"
  type = string
}

variable "model_uri" {
  description = "URI to the MLFlow model"
  type = string
}

variable "env" {
  description = "Set variable depending on environemnt - appended to resources."
  type = string
  default = "stg"
}
