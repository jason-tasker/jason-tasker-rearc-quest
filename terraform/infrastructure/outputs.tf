output "ecr_url" {
  value = aws_ecr_repository.project_ecr.repository_url
}

output "ecr_name" {
  value = "${var.project_name}-ecr"
}