module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  app_port     = var.app_port
}

module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  ecs_sg_id          = module.security.ecs_sg_id
  app_port           = var.app_port
  container_image    = var.container_image
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  min_tasks          = var.min_tasks
  max_tasks          = var.max_tasks
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name     = var.project_name
  environment      = var.environment
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_name = module.compute.ecs_service_name
  alb_arn_suffix   = module.compute.alb_arn_suffix
  aws_region       = var.aws_region 
}
