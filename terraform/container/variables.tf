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

variable "project_owner" {
  description = "Project Owner"
  default     = "Jason Tasker"
  type        = string
}

variable "artifact_bucket" {
  description = "S3 bucket to store artifacts"
  default     = "tasker-demo-artifact"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR block allowed access to deployed resources"
  default     = "99.32.72.96/32"
  type        = string
}
