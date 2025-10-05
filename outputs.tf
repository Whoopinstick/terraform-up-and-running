output "public_ip_second_instance_with_user_data" {
  value       = aws_instance.second_instance_with_user_data.public_ip
  description = "The public IP of the second example instance"
}