variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where instances will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "web_security_group_id" {
  description = "Security group ID for web servers"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID for app servers"
  type        = string
}

variable "db_security_group_id" {
  description = "Security group ID for database"
  type        = string
}

variable "instance_type_web" {
  description = "Instance type for web servers"
  type        = string
  default     = "t2.micro"
}

variable "instance_type_app" {
  description = "Instance type for application servers"
  type        = string
  default     = "t2.micro"
}

variable "instance_type_db" {
  description = "Instance type for database"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
