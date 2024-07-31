variable "bucket_name" {
  description = "Name of the bucket"
}

variable "env" {
  description = "Set variable depending on environemnt - appended to resources."
  type = string
  default = "stg"
}
