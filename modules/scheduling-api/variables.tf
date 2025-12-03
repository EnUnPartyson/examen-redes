variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the API will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for API servers"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID for API servers"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener to attach API rules"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Instance type for API servers"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of API instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of API instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of API instances"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "db_endpoint" {
  description = "Database endpoint for the API"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appointments"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "api_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
