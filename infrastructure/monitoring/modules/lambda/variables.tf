variable "report_bucket" {
  description = "Name of report the bucket"
  type = string
}

variable "lambda_function_name" {
  description = "Name of the lambda function"
  type = string
}

variable "image_uri" {
  description = "ECR Image uri"
  type = string
}

variable "mlflow_run_id" {
  description = "Run ID of the MLFlow run to monitor"
  type = string
}

variable "mlflow_model_bucket" {
  description = "Bucket name where model artifacts are stored"
  type = string
}

variable "monitoring_data_bucket" {
  description = "Bucket name where test and reference data is stored"
  type = string
}
