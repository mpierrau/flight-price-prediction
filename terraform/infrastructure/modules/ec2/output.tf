output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.prediction_service.id
}

output "ip" {
  description = "Public (Elastic) IP address of the EC2 instance"
  value = "${aws_eip_association.eip_assoc.public_ip}"
}
