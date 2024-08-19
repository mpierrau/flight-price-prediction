resource "aws_db_instance" "mlflow-db" {
  allocated_storage      = var.db_allocated_storage #10
  db_name                = "mlflowdb"
  identifier             = "${var.app_name}-${var.env}-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  username               = "mlflow_db_user"
  password               = random_password.db_password.result
  vpc_security_group_ids = var.db_security_groups
  publicly_accessible    = "true"
  db_subnet_group_name   = var.db_subnet_group_name
  skip_final_snapshot    = true
  storage_encrypted      = true

  #depends_on = [aws_internet_gateway.main]
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#-_=+:?"
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.app_name}/${var.env}/DB_PASSWORD"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "db_url" {
  name  = "/${var.app_name}/${var.env}/DATABASE_URL"
  type  = "SecureString"
  value = "postgresql://${aws_db_instance.mlflow-db.username}:${random_password.db_password.result}@${aws_db_instance.mlflow-db.address}:5432/${aws_db_instance.mlflow-db.db_name}"
}

resource "random_password" "mlflow_password" {
  length           = 16
  special          = true
  override_special = "!#-_=+:?"
}

resource "aws_ssm_parameter" "mlflow_password" {
  name  = "/${var.app_name}/${var.env}/MLFLOW_TRACKING_PASSWORD"
  type  = "SecureString"
  value = random_password.mlflow_password.result
}
