resource "aws_ecs_cluster" "justreadit_cluster" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "justreadit_task_definition" {
  family                   = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # Required with Fargate, each task gets its own ENI/IP
  cpu                      = 256      # 0.25 vCPU 
  memory                   = 512      # 512 MiB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${local.name}-api-container"
      image     = "536210620889.dkr.ecr.ca-central-1.amazonaws.com/private-repo-justreadit:latest"
      essential = true

      portMappings = [
        {
          containerPort = 7070
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group        = aws_cloudwatch_log_group.justreadit_log_group.name
          awslogs-region       = "ca-central-1"
          aslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = local.tags
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${local.name}-ecs-service"
  cluster         = aws_ecs_cluster.justreadit_cluster.id
  task_definition = aws_ecs_task_definition.justreadit_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id]
    security_groups  = [aws_security_group.sg_ecs_task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_name   = "justreadit-api-container"
    container_port   = 7070
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy
  ]

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "justreadit_log_group" {
  name              = "/ecs/${local.name}-api"
  retention_in_days = 7

  tags = local.tags
}