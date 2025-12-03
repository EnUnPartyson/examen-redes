output "api_security_group_id" {
  description = "ID of the API security group"
  value       = aws_security_group.api.id
}

output "api_asg_name" {
  description = "Name of the API auto scaling group"
  value       = aws_autoscaling_group.api.name
}

output "api_asg_arn" {
  description = "ARN of the API auto scaling group"
  value       = aws_autoscaling_group.api.arn
}

output "api_target_group_arn" {
  description = "ARN of the API target group"
  value       = var.alb_listener_arn != "" ? aws_lb_target_group.api[0].arn : null
}

output "api_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.api.name
}

output "api_endpoint" {
  description = "API endpoint path"
  value       = "/api/scheduling"
}

output "api_iam_role_arn" {
  description = "ARN of the IAM role for API instances"
  value       = aws_iam_role.api.arn
}
