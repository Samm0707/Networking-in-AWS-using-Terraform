terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Using a recent, stable version
    }
  }
  required_version = ">= 1.2" # Ensuring compatibility with modern Terraform features
}

provider "aws" {
  region = var.aws_region
}