data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-mantic-23.10-amd64-server-*"]
  }

  filter {
        name   = "virtualization-type"
        values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical

}

# add elastic ip to not have to change
# ip all the time when calling
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
}

# actual ec2 instance
resource "aws_instance" "prediction_service" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.profile.name
  key_name = aws_key_pair.default.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    touch user_data_artifact
    sudo apt-get update
    sudo apt-get install awscli docker.io -y
    sudo systemctl start docker
    sudo chmod 777 /var/run/docker.sock
    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    # Pulling the image from ECR
    docker pull ${var.docker_image}
    # Run application on start
    docker run --restart=always -d -p ${var.api_port}:${var.api_port} -e MLFLOW_MODEL_URI=${var.model_uri} ${var.docker_image}
  EOF
}

# attach eip to instance
resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.prediction_service.id
  allocation_id = aws_eip.elastic_ip.id

}
