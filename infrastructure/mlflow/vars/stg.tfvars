env = "stg"
aws_region = "eu-north-1"
app_name = "mlflow-tf"
ecs_service_name = "mlflow-test"
ecs_task_name = "mlflow-test"
your_vpn = "0.0.0.0/0" #Change this to your IP!
db_allocated_storage = 10
db_engine = "postgres"
db_engine_version = "16.3"
db_instance_class = "db.t3.micro"

# Cidr blocks
cidr = "10.0.0.0/25"
private_cidr_a = "10.0.0.0/28"
private_cidr_b = "10.0.0.16/28"
db_cidr_a = "10.0.0.32/28"
db_cidr_b = "10.0.0.48/28"
public_cidr_a = "10.0.0.96/28"
public_cidr_b = "10.0.0.112/28"
