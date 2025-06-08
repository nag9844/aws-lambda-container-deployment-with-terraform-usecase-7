terraform {
  backend "s3" {
    bucket       = "usecases-terraform-state-bucket"
    key          = "usecase7/ecr/statefile.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}