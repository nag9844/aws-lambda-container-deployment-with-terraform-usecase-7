terraform {
  backend "s3" {
	bucket         = "usecases-terraform-state-bucket"
	key            = "usecase6/dev/terraform.tfstate"
	region         = "ap-south-1"
	encrypt        = true
	use_lockfile   = true
  }
}