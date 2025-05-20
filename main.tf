locals {
  # Ensure the number of subnets matches the number of AZs
  az_count = length(var.availability_zones)
  tags = {
    Project     = var.project_name
    Terraform   = "true"
    Environment = "dev" // Example environment tag
  }
}

# --- Virtual Private Cloud (VPC) ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# --- Internet Gateway (IGW) ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.project_name}-igw"
  })
}

# --- Public Subnets ---
resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-subnet-${var.availability_zones[count.index]}"
  })
}

# --- Private Subnets ---
resource "aws_subnet" "private" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-subnet-${var.availability_zones[count.index]}"
  })
}

# --- Elastic IPs for NAT Gateways ---
resource "aws_eip" "nat_gw_eip" {
  count  = local.az_count # One EIP per NAT Gateway/AZ
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.project_name}-nat-gw-eip-${var.availability_zones[count.index]}"
  })
}

# --- NAT Gateways (One per AZ for High Availability) ---
resource "aws_nat_gateway" "nat_gw" {
  count         = local.az_count
  allocation_id = aws_eip.nat_gw_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # NAT GW resides in a public subnet

  tags = merge(local.tags, {
    Name = "${var.project_name}-nat-gw-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.igw] # Ensure IGW is available
}

# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Route all internet-bound traffic to IGW
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-rtb"
  })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Tables (One per AZ, routing to its respective NAT Gateway) ---
resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0" # Route all internet-bound traffic from private subnets to NAT GW
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-rtb-${var.availability_zones[count.index]}"
  })
}

# Associate Private Subnets with their respective Private Route Tables
resource "aws_route_table_association" "private" {
  count          = local.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}