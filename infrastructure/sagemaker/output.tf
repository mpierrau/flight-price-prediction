output "endpoint_name" {
  value = module.model.sagemaker_endpoint_name
}

output "endpoint_arn" {
  value = module.model.sagemaker_endpoint_arn
}

output "endpoint_config_name" {
  value = module.model.sagemaker_endpoint_config_name
}

output "endpoint_config_name_dummy" {
  value = module.model.sagemaker_endpoint_config_name_dummy
}
