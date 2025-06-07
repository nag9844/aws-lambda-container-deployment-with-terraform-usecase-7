output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_config" {
  description = "Backend configuration for Terraform"
  value = {
    bucket     = aws_s3_bucket.terraform_state.bucket
    region     = var.aws_region
    encrypt    = true
    use_lockfile = true
  }
}