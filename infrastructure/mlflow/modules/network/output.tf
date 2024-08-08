# VPC
output "db_subnet_group_name" {
  value = module.vpc.db_subnet_group_name
}

output "private_subnet_a_id" {
  value = module.vpc.private_subnet_a_id
}

output "private_subnet_b_id" {
  value = module.vpc.private_subnet_b_id
}

# Security groups
output "security_group_allow_ingress_from_vpn" {
  value = module.security_groups.security_group_allow_ingress_from_vpn
}

output "security_group_rds" {
  value = module.security_groups.security_group_rds
}

output "ecs_security_group_id" {
  value = module.security_groups.ecs_security_group_id
}

# Gateway
output "main_gateway" {
  value = module.gateway.main_gateway
}

# Load balancer
output "mlflow_lb_target_group_arn" {
  value = module.load_balancer.mlflow_lb_target_group_arn
}

# These are only returned because the RDS module
# implicitly depend on them without reference
output "mlflow_alb_listener" {
  value = module.load_balancer.mlflow_alb_listener
}

output "mlflow_aws_lb" {
  value = module.load_balancer.mlflow_aws_lb
}

output "mlflow_lb_listener_rule" {
  value = module.load_balancer.mlflow_lb_listener_rule
}
