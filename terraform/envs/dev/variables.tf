variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
}

variable "container_image" {
  description = "Docker image URI for ECS task"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for ECS task"
  type        = number
}

variable "task_memory" {
  description = "Memory in MB for ECS task"
  type        = number
}

variable "min_tasks" {
  description = "Minimum number of ECS tasks"
  type        = number
}

variable "max_tasks" {
  description = "Maximum number of ECS tasks"
  type        = number
}
