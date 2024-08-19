resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_a
  availability_zone = var.zone_a
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_b
  availability_zone = var.zone_b
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr_a
  availability_zone = var.zone_a
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr_b
  availability_zone = var.zone_b
}

resource "aws_subnet" "db_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_cidr_a
  availability_zone = var.zone_a
}

resource "aws_subnet" "db_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_cidr_b
  availability_zone = var.zone_b
}

# The DB config requires a subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.app_name}-${var.env}-db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_a.id, aws_subnet.db_subnet_b.id]
}
