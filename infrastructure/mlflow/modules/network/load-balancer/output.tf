output "mlflow_lb_target_group_arn" {
  value = aws_lb_target_group.mlflow.arn
}

output "mlflow_alb_listener" {
  value = aws_alb_listener.mlflow
}

output "mlflow_aws_lb" {
  value = aws_lb.mlflow
}

output "mlflow_lb_listener_rule" {
  value = aws_lb_listener_rule.mlflow
}
