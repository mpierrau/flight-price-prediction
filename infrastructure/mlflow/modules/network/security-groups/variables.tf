variable "vpc_id" {
  description = "ID of main VPC"
  type = string
}

variable "your_vpn" {
  description = "Personal VPN cidr"
  type = string
}

variable "app_name" {
  description = "Name of ECS app"
  type = string
}

variable "internet_cidr" {
  description = "Cidr for access to internet"
  type = string
}

variable "env" {
  description = "value"
  type = string
}
