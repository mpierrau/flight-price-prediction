variable "vpc_id" {
  description = "ID of main VPC"
  type = string
}

variable "internet_cidr" {
  description = "Cidr block for access from internet"
  type = string
}

variable "gateway_id" {
  description = "ID of the NAT gateway, for access to internet"
  type = string
}

variable "mlflow_nat_a_id" {
  description = "ID of NAT for mlflow server in zone a"
  type = string
}
variable "mlflow_nat_b_id" {
  description = "ID of NAT for mlflow server in zone b"
  type = string
}

variable "public_subnet_a_id" {
  description = "ID of public subnet in zone a"
  type = string
}

variable "public_subnet_b_id" {
  description = "ID of public subnet in zone b"
  type = string
}

variable "private_subnet_a_id" {
  description = "ID of private subnet in zone a"
  type = string
}

variable "private_subnet_b_id" {
  description = "ID of private subnet in zone b"
  type = string
}

variable "db_subnet_a_id" {
  description = "ID of db subnet in zone a"
  type = string
}

variable "db_subnet_b_id" {
  description = "ID of db subnet in zone b"
  type = string
}
