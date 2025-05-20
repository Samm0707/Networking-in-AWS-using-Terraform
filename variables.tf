variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Example: Change to your desired region
}

variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
  default     = "core-network"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "A list of two Availability Zones to use in the selected region."
  type        = list(string)
  # Ensure these AZs are valid for your chosen var.aws_region
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (must match number of AZs)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (must match number of AZs)."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}