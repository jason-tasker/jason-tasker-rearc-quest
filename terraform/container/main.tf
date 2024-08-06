# Terraform 0.13 and later

terraform {
  backend "s3" {
    bucket = "tasker-demo-artifact"
    key    = "terraform/tasker-demo-container.tfstate"
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

# Deploy ECS
module "ecs" {
  source          = "./modules/ecs"
  aws_region      = var.aws_region
  project_name    = var.project_name
  project_owner   = var.project_owner
  artifact_bucket = var.artifact_bucket
  allowed_cidr    = var.allowed_cidr
} 
