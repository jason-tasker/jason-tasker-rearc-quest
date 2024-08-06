variable "aws_region" {
  description = "AWS Deployment Region"
}

variable "project_name" {
  description = "Project Name"
}

variable "project_owner" {
  description = "Project Owner"
  default     = "Jason Tasker"
}

variable "artifact_bucket" {
  description = "S3 bucket for artifacts"
}
variable "allowed_cidr" {
  description = "Allowed CIDR Block"
}
