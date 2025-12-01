variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "examen-redes"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
