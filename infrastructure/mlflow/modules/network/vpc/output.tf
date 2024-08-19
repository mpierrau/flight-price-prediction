output "vpc_id" {
  value = aws_vpc.main.id
}

# Public subnets used by load balancer
output "public_subnet_a_id" {
  value = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_subnet_b.id
}

# Private subnets for the ECS
output "private_subnet_a_id" {
  value = aws_subnet.private_subnet_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_subnet_b.id
}

# Subnets
output "db_subnet_a_id" {
  value = aws_subnet.db_subnet_a.id
}

output "db_subnet_b_id" {
  value = aws_subnet.db_subnet_b.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.db_subnet_group.name
}
