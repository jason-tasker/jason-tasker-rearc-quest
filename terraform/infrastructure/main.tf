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

# Modules

# Setup AWS networking resources
module "networking" {
  source          = "./modules/networking"
  aws_region      = var.aws_region
  base_cidr_block = var.base_cidr_block
  project_name    = var.project_name
  project_owner   = var.project_owner
}

# Create ECR repo
module "ecr" {
  source          = "./modules/ecr"
  aws_region      = var.aws_region
  project_name    = var.project_name
  project_owner   = var.project_owner
  artifact_bucket = var.artifact_bucket
} 
