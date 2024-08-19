variable "region" {
  type = string
  description = "AWS region"
}

variable "env" {
  type = string
  description = "Environment"
}

variable "ecs_task_name" {
  type = string
  description = "Name of ECS task"
}

variable "ecs_service_name" {
  type = string
  description = "Name of ECS service"
}

variable "ecs_mlflow_role_arn" {
  type = string
  description = "ARN to IAM role for executing ECS, accessing SSM and CloudWatch"
}

variable "app_name" {
  type = string
  description = "Name of mlflow app, for SSM path"
}

variable "lb_target_group_arn" {
  type = string
  description = "ARN to load balancer target group"
}

variable "ecs_sg_id" {
  type = string
  description = "ID of ECS security group"
}

variable "rds_sg_id" {
  type = string
  description = "ID of RDS security group"
}

variable "private_subnet_a_id" {
  type = string
  description = "ID of private subnet a"
}

variable "private_subnet_b_id" {
  type = string
  description = "ID of private subnet b"
}

variable "mlflow_ecr_image_url" {
  type = string
  description = "ECR image for mlflow container"
}
