# Terraform 1.2.0 and later
# Create S3 bucket first to store TF statefile

terraform {
  backend "s3" {
    bucket = "tasker-demo-artifact"
    key    = "terraform/tasker-demo-infrastructure.tfstate"
    region = "us-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure Data for AZ
data "aws_availability_zones" "available" {}

# Setup AWS networking resources
module "networking" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name} VPC"
  cidr = var.base_cidr_block

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(var.base_cidr_block, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.base_cidr_block, 8, k + 4)]

  enable_nat_gateway = true
  single_nat_gateway = true

}

# Setup ECR for project
resource "aws_ecr_repository" "project_ecr" {
  name                 = "${var.project_name}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
