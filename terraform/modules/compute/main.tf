resource "aws_ecr_repository" "app" {                                    //creates a private Docker image registry in AWS
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"                                       //allows overwriting image tags

  image_scanning_configuration {
    scan_on_push = true                                                 //automatically scans every pushed image for vulnerabilities
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"               //creates an empty ECS cluster
                                                                        //No compute here yet - fargate provides compute on demand
  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({                                //allows ecs-tasks.amazonaws.com service to use this role
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
//AmazonECSTaskExecutionRolePolicy — grants exactly those 2 permissions (ECR pull + CloudWatch logs)
//Without this role, ECS cannot start your container
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"                  //each task gets its own private ip from vpc subnet
  requires_compatibilities = ["FARGATE"]              //AWS manages the underlying EC2 servers, you only define the container
  cpu                      = var.task_cpu   
  memory                   = var.task_memory          //comes from terraform.tfvars different per environment
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-${var.environment}"
    image = var.container_image                //the ECR image URI passed in by the pipeline
    portMappings = [{
      containerPort = var.app_port
      protocol      = "tcp"
    }]
    logConfiguration = {                          //sends all container logs to the cloudWatch log group created above
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
    healthCheck = {                                            //ECS runs curl /health every 30s inside the container. IF it fails 3 times -> task is marked unhealthy and replaced
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60                                       //gives container 60 seconds to start up before health checks begin
    }
  }])

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb" "main" {                          //Creates internet-facing ALB in public subnet 
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false                        //accessible from internet
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]              //comes from security module, allows port 80 from internet
  subnets            = var.public_subnet_ids        //comes from networking module

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"               //required for Fargate awsvpc mode, registers container IPs directly
  health_check {
    path                = "/health"  //if 2 consecutive passes -> heealthy, if 3 consecutive fails -> unhealthy and than traffic will stop going to that task
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_listener" "http" {     //Tells ALB to listen on port 80 and forward all traffic to the TG
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.min_tasks                       //takes always running--if one crashes, ECS starts a new one
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids          //tasks run in private subnets, not directly reachable from internet
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false                        //tasks have no public ip, only reachable via ALB
  }

  load_balancer {                                   //registers each task's IP into the ALB target group automatically
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-${var.environment}"
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.http]             //ensures listner exists before service tries ti register with it

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_appautoscaling_target" "ecs" {   //It registers the ECS service as something that can be scaled
  max_capacity       = var.max_tasks
  min_capacity       = var.min_tasks
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-${var.environment}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
//if average CPU across all task > 70% than add more task if not than remove tasks
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
