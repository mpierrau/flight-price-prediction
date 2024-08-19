output "lambda_function" {
  value = var.lambda_function_name
}

output "report_bucket" {
  value = aws_s3_bucket.report_bucket.bucket
}

output "ecr_repo" {
  value = module.ecr_image.image_uri
}
