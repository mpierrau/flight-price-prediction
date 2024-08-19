variable "app_name" {
  type = string
  description = "Name of 'app', i.e. the mlflow service. Used for naming."
}

variable "env" {
  type = string
  description = "Which environment. E.g. 'stg', 'prod', 'dev'"
}
