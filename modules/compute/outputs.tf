output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.web.zone_id
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = aws_lb_listener.web.arn
}

output "web_target_group_arn" {
  description = "ARN of the web target group"
  value       = aws_lb_target_group.web.arn
}

output "web_asg_name" {
  description = "Name of the web auto scaling group"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Name of the application auto scaling group"
  value       = aws_autoscaling_group.app.name
}

output "db_endpoint" {
  description = "Endpoint of the RDS database"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "Address of the RDS database"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port of the RDS database"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Username for the database"
  value       = aws_db_instance.main.username
  sensitive   = true
}
