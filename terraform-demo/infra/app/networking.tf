resource "aws_vpc" "justreadit_vpc" {
  cidr_block = "10.0.0.0/24"

  tags = merge(local.tags, {
    Name = "${local.name}-vpc"
  })
}

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.justreadit_vpc.id

  tags = merge(local.tags, {
    Name = "${local.name}-igw"
  })
}

resource "aws_route_table" "justreadit_route_table" {
  vpc_id = aws_vpc.justreadit_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }

  tags = merge(local.tags, {
    Name = "${local.name}-rt"
  })
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.justreadit_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.tags, {
    Name = "${local.name}-public-subnet-1"
  })
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.justreadit_vpc.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.tags, {
    Name = "${local.name}-public-subnet-2"
  })
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.justreadit_vpc.id
  cidr_block        = "10.0.0.32/28"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.tags, {
    Name = "${local.name}-private-subnet-1"
  })
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.justreadit_vpc.id
  cidr_block        = "10.0.0.48/28"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.tags, {
    Name = "${local.name}-private-subnet-2"
  })
}

resource "aws_route_table_association" "public_subnet_1_rt_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.justreadit_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_rt_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.justreadit_route_table.id
}

resource "aws_lb" "alb" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb_https.id]

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  # ALB access logs not configured for the demo
  #access_logs {
  #  bucket  = aws_s3_bucket.lb_logs.id
  #  prefix  = "test-lb"
  #  enabled = true
  #}

  tags = local.tags
}

resource "aws_lb_target_group" "alb_tg" {
  name        = "${local.name}-alb-tg"
  port        = 7070
  protocol    = "HTTP" # ALB supports HTTP or HTTPS
  target_type = "ip"
  vpc_id      = aws_vpc.justreadit_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 3 # 3 consecutive successful health check for a target to be considered healthy
    unhealthy_threshold = 2
    interval            = 30  # 3 seconds between checks
    matcher             = 200 # HTTP response for a success
    path                = "/status"
    timeout             = 5
  }
}

resource "aws_lb_listener" "alb_listener_front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"   # 443 during improvement pass
  protocol          = "HTTP" # HTTPS during improvement pass
  # ssl_policy        = # Set during improvement pass
  # certificate_arn   = # Set during improvement pass

  default_action {
    type             = "forward" # Forwards HTTP traffic to target group, which is configured with the backend port 7070
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}