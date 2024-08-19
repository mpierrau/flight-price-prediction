resource "aws_internet_gateway" "main" {
  vpc_id = var.vpc_id
}

resource "aws_eip" "nat_ip_a" {
  domain   = "vpc"
}

resource "aws_eip" "nat_ip_b" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "mlflow_nat_a" {
  allocation_id = aws_eip.nat_ip_a.id
  subnet_id     = var.public_subnet_a_id

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "mlflow_nat_b" {
  allocation_id = aws_eip.nat_ip_b.id
  subnet_id     = var.public_subnet_b_id

  depends_on = [aws_internet_gateway.main]
}
