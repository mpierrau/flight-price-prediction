
output "ecr_repo" {
  value = "${var.ecr_repo_name}_${var.project_id}"
}

output "model_bucket" {
  value = module.s3_bucket.name
}

output "model_uri" {
  value = module.sagemaker.model_uri
}

output "endpoint_name" {
  value = module.sagemaker.name
}
