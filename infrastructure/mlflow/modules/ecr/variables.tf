variable "app_name" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  description = "AWS region to use"
  type = string
}

variable "ecr_image_tag" {
  description = "Docker image tag to use"
  type = string
}

variable "src_dir" {
  description = "Directory with source code. Used to monitor for changes."
  type = string
}
