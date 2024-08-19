variable "sns_topic_arn" {
  description = "SNS topic to post alarms to"
  type = string
}

variable "endpoint_name" {
  description = "Name of the endpoint to create alarms for"
  type = string
}

variable "variant_name" {
  description = "Name of the endpoint variant to create alarms for"
  type = string
}
