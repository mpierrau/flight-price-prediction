variable "app_name" {
  description = "Name of the app"
  type = string
}

variable "cidr" {
  description = "Cidr block of vpc"
  type = string
}

variable "private_cidr_a" {
  description = "Cidr block for private subnet a"
  type = string
}

variable "private_cidr_b" {
  description = "Cidr block for private subnet b"
  type = string
}

variable "public_cidr_a" {
  description = "Cidr block for 'public' subnet b"
  type = string
}

variable "public_cidr_b" {
  description = "Cidr block for 'public' subnet b"
  type = string
}

variable "db_cidr_a" {
  description = "Cidr block for mlflow db in zone a"
  type = string
}

variable "db_cidr_b" {
  description = "Cidr block for mlflow db in zone b"
  type = string
}

variable "zone_a" {
  description = "Availability zone for subnet a"
  type = string
}

variable "zone_b" {
  description = "Availability zone for subnet b"
  type = string
}

variable "internet_cidr" {
  description = "Cidr block for access from internet"
  type = string
}

variable "your_vpn" {
  description = "Your VPN IP adress."
  type = string

}

variable "env" {
  description = "value"
  type = string
}
