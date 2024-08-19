# These are only here for naming and may be changed
env = "stg"

# Switch to your preferred region if you want
# May require updates to db_instance_class if the
# current class is not available in your region
aws_region = "eu-north-1"

# DB Settings
db_allocated_storage = 10
db_engine = "postgres"
db_engine_version = "16.3"
db_instance_class = "db.t3.micro"

# Change this to your VPN/IP if you want. (For testing it's fine to leave as is)
# Should not be left as 0.0.0.0/0 in production
your_vpn = "0.0.0.0/0"

# Don't change these unless you know what you are doing
app_name = "mlflow-tf"
ecs_service_name = "mlflow-svc"
ecs_task_name = "mlflow-task"

# Cidr blocks, don't change these unless you know what you are doing
cidr = "10.0.0.0/25"
private_cidr_a = "10.0.0.0/28"
private_cidr_b = "10.0.0.16/28"
db_cidr_a = "10.0.0.32/28"
db_cidr_b = "10.0.0.48/28"
public_cidr_a = "10.0.0.96/28"
public_cidr_b = "10.0.0.112/28"
