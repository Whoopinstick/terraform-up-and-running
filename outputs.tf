output "public_ip_second_instance_with_user_data" {
  value       = aws_instance.second_instance_with_user_data.public_ip
  description = "The public IP of the second example instance"
}

output "alb_dns_name" {
  value       = aws_lb.lb_third_instance.dns_name
  description = "The domain name of the load balancer in the 3rd example"
}
