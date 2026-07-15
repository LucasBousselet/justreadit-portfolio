resource "aws_security_group" "sg_alb_https" {
  name        = "${local.name}-sg-alb"
  description = "Allow HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_https_ipv4" {
  security_group_id = aws_security_group.sg_alb_https.id
  # Only accepts traffic from CloudFront prefix list.
  # Any CloudFront distribution will match, an improvement for a more secure setup is to use a custom origin header.
  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id 
  
  from_port         = 80 # 443 once HTTPS is configured
  ip_protocol       = "tcp"
  to_port           = 80 # 443 once HTTPS is configured
}

resource "aws_vpc_security_group_egress_rule" "allow_alb_all_outbound_ipv4" {
  security_group_id = aws_security_group.sg_alb_https.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "sg_ecs_task" {
  name        = "${local.name}-sg-ecs-task"
  description = "Allow 7070 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_7070_from_alb" {
  security_group_id            = aws_security_group.sg_ecs_task.id
  from_port                    = 7070
  ip_protocol                  = "tcp"
  to_port                      = 7070
  referenced_security_group_id = aws_security_group.sg_alb_https.id # Traffic allowed only from ALB SG
}

resource "aws_vpc_security_group_egress_rule" "allow_ecs_all_outbound_ipv4" {
  security_group_id = aws_security_group.sg_ecs_task.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "sg_rds" {
  name        = "${local.name}-sg-rds"
  description = "Allow Postgres inbound traffic from ECS SG and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgres_inbound_ipv4" {
  security_group_id            = aws_security_group.sg_rds.id
  referenced_security_group_id = aws_security_group.sg_ecs_task.id # Traffic allowed only from ECS SG
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_rds_all_outbound_ipv4" {
  security_group_id = aws_security_group.sg_rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}