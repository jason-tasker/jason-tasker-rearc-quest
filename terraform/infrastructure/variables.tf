variable "aws_region" {
  description = "AWS Deployment Region"
  default     = "us-west-2"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  default     = "tasker-demo-auto"
  type        = string
}

variable "base_cidr_block" {
  description = "Base CIDR block for VPC and Subnets"
  default     = "10.0.0.0/16"
  type        = string
}