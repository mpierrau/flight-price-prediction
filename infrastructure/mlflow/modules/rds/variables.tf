variable "app_name" {
  description = "Name of ECS app"
  type = string
}

variable "db_subnet_group_name" {
  description = "Name of subnet group for DB"
  type = string
}

variable "db_security_groups" {
  description = "Security groups for access to DB"
  type = list(string)
}

variable "db_allocated_storage" {
  description = "How many GB to allocate to DB storage"
  type = number
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
  description = "Which EC2 instance for DB to use"
  type = string
}

variable "env" {
  description = "Environment tag"
  type = string
}
