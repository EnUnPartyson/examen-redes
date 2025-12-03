# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = module.network.nat_gateway_ips
}

output "web_security_group_id" {
  description = "Security group ID for web servers"
  value       = module.network.web_security_group_id
}

output "app_security_group_id" {
  description = "Security group ID for application servers"
  value       = module.network.app_security_group_id
}

output "db_security_group_id" {
  description = "Security group ID for database servers"
  value       = module.network.db_security_group_id
}

# Application Outputs
output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.compute.alb_dns_name}"
}

output "scheduling_api_url" {
  description = "URL to access the scheduling API"
  value       = "http://${module.compute.alb_dns_name}/api/scheduling"
}

output "api_endpoints" {
  description = "API endpoint paths"
  value = {
    health       = "/api/scheduling/health"
    info         = "/api/scheduling/info"
    appointments = "/api/scheduling/appointments"
    statistics   = "/api/scheduling/statistics"
  }
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "web_asg_name" {
  description = "Name of the web auto scaling group"
  value       = module.compute.web_asg_name
}

output "app_asg_name" {
  description = "Name of the application auto scaling group"
  value       = module.compute.app_asg_name
}

output "database_endpoint" {
  description = "Endpoint of the RDS MySQL database"
  value       = module.compute.db_endpoint
}

output "database_name" {
  description = "Name of the database"
  value       = module.compute.db_name
}
