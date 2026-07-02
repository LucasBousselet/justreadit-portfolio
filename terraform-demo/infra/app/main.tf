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

resource "aws_vpc" "justreadit_vpc" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Product = "justreadit"
  }
}

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.justreadit_vpc.id

  tags = {
    Product = "justreadit"
  }
}

resource "aws_route_table" "justreadit_route_table" {
  vpc_id = aws_vpc.justreadit_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }

  tags = {
    Product = "justreadit"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.justreadit_vpc.id
  cidr_block = "10.0.0.0/28"

  tags = {
    Product = "justreadit"
  }
}

resource "aws_route_table_association" "public_subnet_1_rt_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.justreadit_route_table.id
}

resource "aws_security_group" "sg_allow_https" {
  name        = "sg_allow_https"
  description = "Allow HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = {
    Product = "justreadit"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.sg_allow_https.id
  cidr_ipv4         = aws_vpc.justreadit_vpc.cidr_block
  from_port         = 7070 # 443 once ALB is in place
  ip_protocol       = "tcp"
  to_port           = 7070 # 443 once ALB is in place
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_ipv4" {
  security_group_id = aws_security_group.sg_allow_https.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
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
  family                   = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
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
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id]
    security_groups  = [aws_security_group.sg_allow_https.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy
  ]

  tags = {
    Product = "justreadit"
  }
}
