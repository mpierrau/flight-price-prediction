# Definition of the task to run - i.e. which
# container to run with which env vars, secrets and options etc
resource "aws_ecs_task_definition" "mlflow" {
  execution_role_arn = var.ecs_mlflow_role_arn
  family       = var.ecs_task_name
  memory       = "3072"
  cpu          = "1024"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]

  container_definitions = jsonencode(
    [
      {
        environment = [
          {
            name  = "DB_PORT"
            value = "5432"
          },
          {
            name  = "MLFLOW_TRACKING_USERNAME"
            value = "mlflow-user"
          },
        ]
        essential = true
        image     = "${var.mlflow_ecr_repo_url}:latest"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/${var.ecs_service_name}/${var.ecs_task_name}"
            awslogs-region        = var.region
            awslogs-stream-prefix = "ecs"
          }
        }
        name = var.ecs_task_name
        portMappings = [
          {
            appProtocol   = "http"
            containerPort = 8080
            hostPort      = 8080
            name          = "${var.ecs_task_name}-8080-tcp"
            protocol      = "tcp"
          },
        ]
        secrets = [
          {
            name      = "AWS_ACCESS_KEY_ID"
            valueFrom = "/${var.app_name}/${var.env}/AWS_ACCESS_KEY_ID"
          },
          {
            name      = "AWS_SECRET_ACCESS_KEY"
            valueFrom = "/${var.app_name}/${var.env}/AWS_SECRET_ACCESS_KEY"
          },
          {
            name      = "MLFLOW_TRACKING_PASSWORD"
            valueFrom = "/${var.app_name}/${var.env}/MLFLOW_TRACKING_PASSWORD"
          },
          {
            name      = "ARTIFACT_URL"
            valueFrom = "/${var.app_name}/${var.env}/ARTIFACT_URL"
          },
          {
            name      = "DATABASE_URL"
            valueFrom = "/${var.app_name}/${var.env}/DATABASE_URL"
          },
        ]
      },
    ]
  )

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_cluster" "mlflow_ecs" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Capacity provider
resource "aws_ecs_cluster_capacity_providers" "base" {
  cluster_name = aws_ecs_cluster.mlflow_ecs.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    weight            = 10
    base              = 1
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_service" "mlflow" {
  health_check_grace_period_seconds = 0
  name                              = var.ecs_service_name
  enable_ecs_managed_tags           = true
  propagate_tags                    = "NONE"
  cluster                           = aws_ecs_cluster.mlflow_ecs.id
  task_definition                   = "${aws_ecs_task_definition.mlflow.family}:${aws_ecs_task_definition.mlflow.revision}"
  desired_count                     = 1

  # Need to wait until the task is defined
  depends_on = [
    aws_ecs_task_definition.mlflow
  ]

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 10
  }

  load_balancer {
    container_name   = var.ecs_task_name
    container_port   = 8080
    target_group_arn = var.lb_target_group_arn #aws_lb_target_group.mlflow.arn
  }

  network_configuration {
    security_groups = [
      var.ecs_sg_id,#aws_security_group.ecs_sg.id,
      var.rds_sg_id#aws_security_group.rds_sg.id,
    ]

    subnets = [
      var.private_subnet_a_id, #aws_subnet.private_subnet_a.id,
      var.private_subnet_b_id #aws_subnet.private_subnet_b.id,
    ]
  }
}
