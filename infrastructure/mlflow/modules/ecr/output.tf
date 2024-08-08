output "mlflow_ecr_repo_url" {
  value = aws_ecr_repository.mlflow_ecr.repository_url
}
