
0s
Run cd terraform
  cd terraform
  terraform init \
    -backend-config="bucket=***" \
    -backend-config="key=hello-world-lambda/prod/terraform.tfstate" \
    -backend-config="region=ap-south-1" \
    -backend-config="use_lockfile=true" \
    -backend-config="encrypt=true"
  shell: /usr/bin/bash -e {0}
  env:
    TF_VERSION: 1.5.0
    AWS_REGION: ap-south-1
    AWS_DEFAULT_REGION: ap-south-1
    AWS_ACCESS_KEY_ID: ***
    AWS_SECRET_ACCESS_KEY: ***
    AWS_SESSION_TOKEN: ***
    TERRAFORM_CLI_PATH: /home/runner/work/_temp/2a8f498d-d2a8-4da4-b56c-cbcb7ef42499

Initializing the backend...
Initializing modules...
- api_gateway in modules/api_gateway
- ecr in modules/ecr
- lambda in modules/lambda
- monitoring in modules/monitoring
- vpc in modules/vpc
╷
│ Error: Invalid backend configuration argument
│ 
│ The backend configuration argument "use_lockfile" given on the command line
│ is not expected for the selected backend type.
╵

Error: Terraform exited with code 1.
Error: Process completed with exit code 1.