module "vpc" {
  source = "./vpc"
  app_name = var.app_name
  cidr = var.cidr
  private_cidr_a = var.private_cidr_a
  private_cidr_b = var.private_cidr_b
  public_cidr_a = var.public_cidr_a
  public_cidr_b = var.public_cidr_b
  db_cidr_a = var.db_cidr_a
  db_cidr_b = var.db_cidr_b
  zone_a = var.zone_a
  zone_b = var.zone_b
  env = var.env
}

module "gateway" {
  source = "./gateway"
  vpc_id = module.vpc.vpc_id
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
}

module "routes" {
  source = "./routes"
  vpc_id = module.vpc.vpc_id
  internet_cidr = var.internet_cidr
  gateway_id = module.gateway.main_gateway.id
  mlflow_nat_a_id = module.gateway.mlflow_nat_a_id
  mlflow_nat_b_id = module.gateway.mlflow_nat_b_id
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
  private_subnet_a_id = module.vpc.private_subnet_a_id
  private_subnet_b_id = module.vpc.private_subnet_b_id
  db_subnet_a_id = module.vpc.db_subnet_a_id
  db_subnet_b_id = module.vpc.db_subnet_b_id
}

module "security_groups" {
  source = "./security-groups"
  vpc_id = module.vpc.vpc_id
  your_vpn = var.your_vpn
  app_name = var.app_name
  internet_cidr = var.internet_cidr
  env = var.env
}

module "load_balancer" {
  source = "./load-balancer"
  vpc_id = module.vpc.vpc_id
  db_security_groups = [ module.security_groups.lb_security_group_id ]
  db_public_subnet_ids = [
    module.vpc.public_subnet_a_id,
    module.vpc.public_subnet_b_id
  ]
  internet_cidr = var.internet_cidr
}
