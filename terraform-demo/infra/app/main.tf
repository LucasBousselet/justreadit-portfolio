terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region  = "ca-central-1"
  profile = "terraform-process" # Uses aws cli profile "terraform-process", which uses short-lived credentials
}

resource "aws_ecs_cluster" "justreadit_cluster" {
  name = "justreadit-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Product = "justreadit"
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Product = "justreadit"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "justreadit_task_definition" {
  family = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "justreadit-api"
      image     = "536210620889.dkr.ecr.ca-central-1.amazonaws.com/private-repo-justreadit:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 7070
        }
      ]
    }
  ])

  tags = {
    Product = "justreadit"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.justreadit_cluster.id
  task_definition = aws_ecs_task_definition.justreadit_task_definition.arn
  desired_count   = 1

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy
  ]

  tags = {
    Product = "justreadit"
  }
}
