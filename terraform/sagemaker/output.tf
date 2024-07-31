output "name" {
  value = aws_sagemaker_endpoint.sagemaker_endpoint.name
}

output "arn" {
  value = aws_sagemaker_endpoint.sagemaker_endpoint.arn
}

output "model_uri" {
  value = local.mlflow_model_uri
}
