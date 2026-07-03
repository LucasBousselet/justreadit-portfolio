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
  vpc_id     = aws_vpc.justreadit_vpc.id
  cidr_block = "10.0.0.0/28"

  tags = merge(local.tags, {
    Name = "${local.name}-public-subnet-1"
  })
}

resource "aws_route_table_association" "public_subnet_1_rt_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.justreadit_route_table.id
}