resource "aws_security_group" "sg" {
  # Allow incoming traffic to SSH port
  ingress {
    from_port = var.ssh_port
    protocol  = "tcp"
    to_port   = var.ssh_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming traffic to API port
  ingress {
    from_port = var.api_port
    protocol  = "tcp"
    to_port   = var.api_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No restriction on destination IP
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
