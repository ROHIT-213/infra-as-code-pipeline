output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
/*Used by monitoring module to attach cloudwatch alarms to the correct service and also used by 
ci-cd.yml to identify which service to rollback*/
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name      
}
//Retuerns the public URL of the ALB, used bt ci-cd.yml
output "alb_dns_name" {
  description = "DNS name of the ALB to access the application"
  value       = aws_lb.main.dns_name
}
//Returns the full ECR URL, used by ci-cd.yml push job to know where to push the Docker image
output "ecr_repository_url" {
  description = "ECR repository URL for pushing Docker images"
  value       = aws_ecr_repository.app.repository_url
}
//Returns the full ARN of the current task definition, used by rollback logic to know which task definition revision to revert to
output "ecs_task_definition_arn" {
  description = "ARN of the current ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}
//rollback logic to know which task definition revision to revert to, suffix because CloudWatch metrics use the suffix format, not the full ARN
output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}
