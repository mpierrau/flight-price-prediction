# General variables
variable "env" {
  description = "Name of the environment"
  type = string
}

variable "aws_region" {
  type = string
}

variable "app_name" {
  type = string
}

# ECS variables
variable "ecs_service_name" {
  type = string
}

variable "ecs_task_name" {
  type = string
}

# Networking variables
# Cidr blocks for the various subnets
# /28 is the smallest allowed size
variable "cidr" {
  default     = "10.0.0.0/25"
  description = "Cidr block of vpc"
  type = string
}

variable "private_cidr_a" {
  default = "10.0.0.0/28"
  type = string
}

variable "private_cidr_b" {
  default = "10.0.0.16/28"
  type = string
}

variable "db_cidr_a" {
  default = "10.0.0.32/28"
  type = string
}

variable "db_cidr_b" {
  default = "10.0.0.48/28"
  type = string
}

variable "public_cidr_a" {
  default = "10.0.0.64/28"
  type = string
}

variable "public_cidr_b" {
  default = "10.0.0.80/28"
  type = string
}

variable "internet_cidr" {
  default     = "0.0.0.0/0"
  description = "Cidr block for the internet"
  type = string
}

# Never use 0.0.0.0/0 in production
variable "your_vpn" {
  default = "0.0.0.0/0"
  description = "Change this variable to your VPN. If you leave 0.0.0.0/0 your application will be accessible from any IP."
  type = string
}

# Availability zones for rds
variable "zone_a" {
  default = "eu-north-1a"
  type = string
}

variable "zone_b" {
  default = "eu-north-1b"
  type = string
}

# RDS variables
variable "db_allocated_storage" {
  description = "GB of storage for database"
  type = string
}
variable "db_engine" {
  description = "Which DB engine/backend to use"
  type = string
}
variable "db_engine_version" {
  description = "Which version of the DB engine/backend to use"
  type = string
}
variable "db_instance_class" {
  description = "EC2 instance to use for hosting DB"
  type = string
}
