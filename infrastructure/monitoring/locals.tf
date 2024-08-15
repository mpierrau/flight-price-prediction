 locals {
  # Common tags to be assigned to all resources
  tags = {
    Name        = "monitoring-terraform"
    Environment = var.env
  }
}
