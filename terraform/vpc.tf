# ==================================
# VPC Configuration for Marketfy
# ==================================

# VPC
resource "aws_vpc" "marketfy" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "marketfy" {
  vpc_id = aws_vpc.marketfy.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets (for ALB)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.marketfy.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

# Private Subnets (for ECS tasks and RDS)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.marketfy.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "private"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.marketfy]
}

# NAT Gateways (for private subnet internet access)
resource "aws_nat_gateway" "marketfy" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.marketfy]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.marketfy.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.marketfy.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 1
  vpc_id = aws_vpc.marketfy.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.marketfy[count.index].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# VPC Flow Logs (Security best practice)
resource "aws_flow_log" "marketfy" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.marketfy.id

  tags = {
    Name = "${var.project_name}-flow-logs"
  }
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-flow-logs"
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-flow-logs-role"
  }
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
