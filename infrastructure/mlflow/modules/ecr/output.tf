output "mlflow_ecr_image_url" {
  value = data.aws_ecr_image.mlflow_image.image_uri
}
