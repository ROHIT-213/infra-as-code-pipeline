variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name from compute module"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name from compute module"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix from compute module (used for ALB metrics)"
  type        = string
}

variable "aws_region" {
  type = string
}