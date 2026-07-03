resource "aws_security_group" "sg_allow_https" {
  name        = "sg_allow_https"
  description = "Allow HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.justreadit_vpc.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.sg_allow_https.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 7070 # 443 once ALB is in place
  ip_protocol       = "tcp"
  to_port           = 7070 # 443 once ALB is in place
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_ipv4" {
  security_group_id = aws_security_group.sg_allow_https.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}