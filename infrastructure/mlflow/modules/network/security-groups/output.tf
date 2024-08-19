output "security_group_allow_ingress_from_vpn" {
  value = aws_security_group.allow_ingress_from_vpn
}

output "security_group_rds" {
  value = aws_security_group.rds_sg
}

output "lb_security_group_id" {
  value = aws_security_group.lb_sg.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_sg.id
}
