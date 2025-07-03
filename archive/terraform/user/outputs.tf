output "aws_instance_public_ip" {
  description = "Public IP Address"
  value       = aws_instance.head_node.public_ip
}