output "model_repo_url" {
  value = data.aws_ecr_image.app_image.image_uri
}
