resource "aws_security_group" "sg_alb_https" {
  name        = "sg_alb_https"
  description = "Allow HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_https_ipv4" {
  security_group_id = aws_security_group.sg_alb_https.id
  cidr_ipv4         = "0.0.0.0/0"
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
  name        = "sg_ecs_task"
  description = "Allow 7070 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_https_ipv4" {
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