
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # module.lambda.aws_lambda_function.main will be updated in-place
  ~ resource "aws_lambda_function" "main" {
        id                             = "hello-world-lambda-dev"
      ~ image_uri                      = "199570228070.dkr.ecr.ap-south-1.amazonaws.com/hello-world-lambda-dev:v1.12.0-20250609-094341-6222a99" -> "199570228070.dkr.ecr.ap-south-1.amazonaws.com/hello-world-lambda-dev:v1.12.0-20250609-095739-1abe3a2"
      ~ last_modified                  = "2025-06-09T09:45:23.000+0000" -> (known after apply)
        tags                           = {
            "Environment" = "dev"
            "Name"        = "hello-world-lambda-lambda-dev"
            "Project"     = "hello-world-lambda"
        }
        # (26 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
