output "main_gateway" {
  value = aws_internet_gateway.main
}

output "mlflow_nat_a_id" {
  value = aws_nat_gateway.mlflow_nat_a.id
}
output "mlflow_nat_b_id" {
  value = aws_nat_gateway.mlflow_nat_b.id
}
