variable "aws_region" {
    description = "AWS region to create resources"
    type = string
}

variable "env" {
  description = "Environment var suffix (stg/prod)"
  type = string
}

variable "project_id" {
  description = "project_id"
  type = string
}

variable "report_bucket_name" {
  description = "Name of the S3 bucket holding generated metric reports"
  type = string
}

variable "reference_data_bucket_name" {
  description = "Name of the S3 bucket holding reference data for metric reports"
  type = string
}

variable "ecr_repo_name" {
  description = "Name of ECR repository for monitoring lambda"
  type = string
}

variable "ecr_image_tag" {
  description = "Tag of ECR docker image"
  type = string
}

variable "lambda_function_name" {
  description = "Name of lambda function"
  type = string
}

variable "mlflow_run_id" {
  description = "Run ID of the MLFlow run to monitor"
  type = string
}

variable "mlflow_tracking_uri" {
  description = "Tracking URI to mlflow server"
  type = string
}

variable "mlflow_artifact_path" {
  description = "Relative path to model artifacts in bucket"
  type = string
}

variable "reference_data_path" {
  description = "Relative path in bucket to reference data"
  type = string
}

variable "src_dir" {
  description = "Directory with source code. Used to monitor for changes."
  type = string
}

variable "mlflow_model_bucket" {
  description = "Bucket name where model artifacts are stored"
  type = string
}
