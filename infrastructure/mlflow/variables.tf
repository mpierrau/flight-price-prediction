# General variables
variable "env" {
  default     = "stg"
  description = "Name of the environment"
}

variable "aws_region" {
  default = "eu-north-1"
}

variable "app_name" {
  default = "mlflow-terraform"
}

# ECS variables
variable "ecs_service_name" {
  default = "mlflow-test"
}

variable "ecs_task_name" {
  default = "mlflow-test"
}

# Networking variables
# Cidr blocks for the various subnets
# /28 is the smallest allowed size
variable "cidr" {
  default     = "10.0.0.0/25"
  description = "Cidr block of vpc"
}

variable "private_cidr_a" {
  default = "10.0.0.0/28"
}

variable "private_cidr_b" {
  default = "10.0.0.16/28"
}

variable "db_cidr_a" {
  default = "10.0.0.32/28"
}

variable "db_cidr_b" {
  default = "10.0.0.48/28"
}

variable "public_cidr_a" {
  default = "10.0.0.64/28"
}

variable "public_cidr_b" {
  default = "10.0.0.80/28"
}

variable "internet_cidr" {
  default     = "0.0.0.0/0"
  description = "Cidr block for the internet"
}

# Never use 0.0.0.0/0 in production
variable "your_vpn" {
  default = "0.0.0.0/0"
  description = "Change this variable to your VPN. If you leave 0.0.0.0/0 your application will be accessible from any IP."
}

# Availability zones for rds
variable "zone_a" {
  default = "eu-north-1a"
}

variable "zone_b" {
  default = "eu-north-1b"
}

# RDS variables
variable "db_allocated_storage" {
  type = string
  description = "GB of storage for database"
}
variable "db_engine" {
  type = string
  description = "Which DB engine/backend to use"
}
variable "db_engine_version" {
  type = string
  description = "Which version of the DB engine/backend to use"
}
variable "db_instance_class" {
  type = string
  description = "EC2 instance to use for hosting DB"
}
