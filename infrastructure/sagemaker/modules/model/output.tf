output "sagemaker_endpoint_name" {
  value = aws_sagemaker_endpoint.sagemaker_endpoint.name
}

output "sagemaker_endpoint_arn" {
  value = aws_sagemaker_endpoint.sagemaker_endpoint.arn
}

output "sagemaker_variant_name" {
  value = var.endpoint_variant_name
}

output "sagemaker_endpoint_config_name" {
  value = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config.name
}

output "sagemaker_endpoint_config_name_dummy" {
  value = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config_dummy.name
}
