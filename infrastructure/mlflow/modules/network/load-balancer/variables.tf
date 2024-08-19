variable "db_security_groups" {
  description = "Security groups for access to ECS"
  type = list(string)
}

variable "db_public_subnet_ids" {
  description = "Public subnet IDs for zones a and b"
  type = list(string)
}

variable "vpc_id" {
  description = "ID of main VPC"
  type = string
}

variable "internet_cidr" {
  description = "Accepted Cidr block for incoming requests"
  type = string
}
