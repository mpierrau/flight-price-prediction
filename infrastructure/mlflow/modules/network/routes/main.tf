# Route for DB and load balancer
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = var.internet_cidr
    gateway_id = var.gateway_id
  }
}

# Routes from NAT gateway to internet
resource "aws_route_table" "private_a" {
  vpc_id = var.vpc_id

  route {
    cidr_block = var.internet_cidr
    nat_gateway_id = var.mlflow_nat_a_id
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = var.vpc_id

  route {
    cidr_block = var.internet_cidr
    nat_gateway_id = var.mlflow_nat_b_id
  }
}

# Route table associations
resource "aws_route_table_association" "private_subnet_association_a" {
  route_table_id = aws_route_table.private_a.id
  subnet_id      = var.private_subnet_a_id
}

resource "aws_route_table_association" "private_subnet_association_b" {
  route_table_id = aws_route_table.private_b.id
  subnet_id      = var.private_subnet_b_id
}

resource "aws_route_table_association" "db_subnet_association_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = var.db_subnet_a_id
}

resource "aws_route_table_association" "db_subnet_association_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = var.db_subnet_b_id
}

resource "aws_route_table_association" "public_subnet_association_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = var.public_subnet_a_id
}

resource "aws_route_table_association" "public_subnet_association_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = var.public_subnet_b_id
}
