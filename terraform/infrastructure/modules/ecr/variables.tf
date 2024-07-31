variable "ecr_repo_name" {
  type = string
  description = "ECR repo name"
}

variable "region" {
  type = string
  description = "AWS region to use"
  default = "eu-north-1"
}

variable "account_id" {
}

variable "env" {
  description = "Set variable depending on environemnt - appended to resources."
  type = string
  default = "stg"
}
