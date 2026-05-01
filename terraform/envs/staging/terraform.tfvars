project_name = "infra-pipeline"
environment  = "staging"
aws_region   = "ap-south-1"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.2.0/24", "10.1.4.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

app_port        = 3000
container_image = "nginx:latest"
task_cpu        = 512
task_memory     = 1024
min_tasks       = 2
max_tasks       = 4
