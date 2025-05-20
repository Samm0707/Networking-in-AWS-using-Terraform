# --- Default Security Group for the VPC ---
# Best practice to manage its rules explicitly, especially egress.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # Allow all instances within this default SG to communicate with each other on all ports.
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  # Allow all outbound traffic by default.
  # You might want to restrict this further in a production environment.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-default-sg"
  })
}

# --- Example Security Group for Public Web Servers ---
# Allows common web traffic and SSH from anywhere.
# IMPORTANT: For production, restrict cidr_blocks for SSH to known IPs.
resource "aws_security_group" "web_access_sg" {
  name        = "${var.project_name}-web-access-sg"
  description = "Allow HTTP, HTTPS, and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (restrict to your IP in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # CHANGE THIS IN PRODUCTION!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-web-access-sg"
  })
}

# --- Default Network ACL (NACL) ---
# AWS creates a default NACL that allows all traffic.
# This resource allows explicit management of its rules.
# Security Groups (stateful) are generally preferred for primary traffic filtering for instances.
# NACLs (stateless) act as an additional layer of defense at the subnet level.
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id

  # Allow all inbound traffic (default behavior)
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all outbound traffic (default behavior)
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-default-nacl"
  })
}