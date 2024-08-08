output "mlflow_ecr_repo_url" {
  value = module.ecr.mlflow_ecr_repo_url
}

output "mlflow_lb_dns" {
  value = module.network.mlflow_aws_lb.dns_name
}
