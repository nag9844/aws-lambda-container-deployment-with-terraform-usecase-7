output "repository_uri" {
  description = "URI of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "ecr_access_policy_arn" {
  description = "ARN of the ECR access policy"
  value       = aws_iam_policy.ecr_access.arn
}