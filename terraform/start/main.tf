# Terraform 1.2.0 and later

# Use S3 bucket store TF statefile

terraform {
  backend "s3" {
    bucket = "tasker-demo-artifact"
    key    = "terraform/tasker-demo-start.tfstate"
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
