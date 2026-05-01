variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for ALB from security module"
  type        = string
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks from security module"
  type        = string
}

variable "app_port" {
  description = "Port the application container listens on"
  type        = number
}

variable "container_image" {
  description = "Docker image URI for the ECS task"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the ECS task (e.g. 256, 512, 1024)"
  type        = number
}

variable "task_memory" {
  description = "Memory in MB for the ECS task (e.g. 512, 1024)"
  type        = number
}

variable "min_tasks" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "max_tasks" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 6
}
