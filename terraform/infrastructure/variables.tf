variable "aws_region" {
  description = "AWS Deployment Region"
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project Name"
  default     = "tasker-demo-auto"
}

variable "project_owner" {
  description = "Project Owner"
  default     = "Jason Tasker"
}

variable "artifact_bucket" {
  description = "S3 bucket to store artifacts"
  default     = "tasker-demo-artifact"
}

variable "allowed_cidr" {
  description = "CIDR block allowed access to deployed resources"
  default     = "99.32.72.96/32"
}

variable "base_cidr_block" {
  description = "Base CIDR block for VPC and Subnets"
  default     = "10.0.0.0/16"
}
