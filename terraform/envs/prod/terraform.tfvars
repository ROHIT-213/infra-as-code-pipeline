project_name = "infra-pipeline"
environment  = "prod"
aws_region   = "ap-south-1"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.2.0/24", "10.2.4.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

app_port        = 3000
container_image = "nginx:latest"
task_cpu        = 1024
task_memory     = 2048
min_tasks       = 2
max_tasks       = 6
