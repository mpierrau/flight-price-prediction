variable "model_prefix" {
  description = "Prefix to prepend to resource names. Typically {project_id}-{env}"
  type = string
}

variable "endpoint_variant_name" {
  description = "Name of the SageMaker endpoint variant"
  type = string
}

variable "model_image_url" {
  description = "URL to built app ECR container"
  type = string
}

variable "mlflow_model_uri" {
  description = "URI to MLFlow model"
  type = string
}

variable "execution_role_arn" {
  description = "ARN of SageMaker execution role"
  type = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type for prediction app"
  type = string
}
