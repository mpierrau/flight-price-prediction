output "mlflow_lb_dns" {
  value = module.network.mlflow_aws_lb.dns_name
  sensitive = true
}
