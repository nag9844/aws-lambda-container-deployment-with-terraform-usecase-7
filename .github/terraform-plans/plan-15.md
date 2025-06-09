
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  # module.api_gateway.aws_api_gateway_stage.main will be updated in-place
  ~ resource "aws_api_gateway_stage" "main" {
      ~ deployment_id         = "ird1hx" -> "v4j6x5"
        id                    = "ags-fjg9abhckd-dev"
        tags                  = {
            "Environment" = "dev"
            "Name"        = "hello-world-lambda-api-stage-dev"
            "Project"     = "hello-world-lambda"
        }
        # (14 unchanged attributes hidden)

        # (1 unchanged block hidden)
    }

  # module.lambda.aws_lambda_function.main will be updated in-place
  ~ resource "aws_lambda_function" "main" {
        id                             = "hello-world-lambda-dev"
      ~ image_uri                      = "199570228070.dkr.ecr.ap-south-1.amazonaws.com/hello-world-lambda-dev:v1.12.0-20250609-105439-17b225e" -> "199570228070.dkr.ecr.ap-south-1.amazonaws.com/hello-world-lambda-dev:v1.12.0-20250609-124405-e2a4ebf"
      ~ last_modified                  = "2025-06-09T10:56:18.000+0000" -> (known after apply)
        tags                           = {
            "Environment" = "dev"
            "Name"        = "hello-world-lambda-lambda-dev"
            "Project"     = "hello-world-lambda"
        }
        # (26 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

  # module.vpc.aws_eip.nat_gateway[0] will be created
  + resource "aws_eip" "nat_gateway" {
      + allocation_id        = (known after apply)
      + arn                  = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = "vpc"
      + id                   = (known after apply)
      + instance             = (known after apply)
      + ipam_pool_id         = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + ptr_record           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Name"        = "hello-world-lambda-nat-eip-1-dev"
          + "Project"     = "hello-world-lambda"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "hello-world-lambda-nat-eip-1-dev"
          + "Project"     = "hello-world-lambda"
        }
      + vpc                  = (known after apply)
    }

  # module.vpc.aws_eip.nat_gateway[1] will be created
  + resource "aws_eip" "nat_gateway" {
      + allocation_id        = (known after apply)
      + arn                  = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = "vpc"
      + id                   = (known after apply)
      + instance             = (known after apply)
      + ipam_pool_id         = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + ptr_record           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Name"        = "hello-world-lambda-nat-eip-2-dev"
          + "Project"     = "hello-world-lambda"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "hello-world-lambda-nat-eip-2-dev"
          + "Project"     = "hello-world-lambda"
        }
      + vpc                  = (known after apply)
    }

  # module.vpc.aws_nat_gateway.main[0] will be created
  + resource "aws_nat_gateway" "main" {
      + allocation_id                      = (known after apply)
      + association_id                     = (known after apply)
      + connectivity_type                  = "public"
      + id                                 = (known after apply)
      + network_interface_id               = (known after apply)
      + private_ip                         = (known after apply)
      + public_ip                          = (known after apply)
      + secondary_private_ip_address_count = (known after apply)
      + secondary_private_ip_addresses     = (known after apply)
      + subnet_id                          = "subnet-0cf8f900c5eb2d2c9"
      + tags                               = {
          + "Environment" = "dev"
          + "Name"        = "hello-world-lambda-nat-gateway-1-dev"
          + "Project"     = "hello-world-lambda"
        }
      + tags_all                           = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "hello-world-lambda-nat-gateway-1-dev"
          + "Project"     = "hello-world-lambda"
        }
    }

  # module.vpc.aws_nat_gateway.main[1] will be created
  + resource "aws_nat_gateway" "main" {
      + allocation_id                      = (known after apply)
      + association_id                     = (known after apply)
      + connectivity_type                  = "public"
      + id                                 = (known after apply)
      + network_interface_id               = (known after apply)
      + private_ip                         = (known after apply)
      + public_ip                          = (known after apply)
      + secondary_private_ip_address_count = (known after apply)
      + secondary_private_ip_addresses     = (known after apply)
      + subnet_id                          = "subnet-0c087a716a9ef9fe3"
      + tags                               = {
          + "Environment" = "dev"
          + "Name"        = "hello-world-lambda-nat-gateway-2-dev"
          + "Project"     = "hello-world-lambda"
        }
      + tags_all                           = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "hello-world-lambda-nat-gateway-2-dev"
          + "Project"     = "hello-world-lambda"
        }
    }

  # module.vpc.aws_route_table.private[0] will be updated in-place
  ~ resource "aws_route_table" "private" {
        id               = "rtb-01ef08488f586f1f7"
      ~ route            = [
          + {
              + cidr_block                 = "0.0.0.0/0"
              + nat_gateway_id             = (known after apply)
                # (11 unchanged attributes hidden)
            },
        ]
        tags             = {
            "Environment" = "dev"
            "Name"        = "hello-world-lambda-private-rt-1-dev"
            "Project"     = "hello-world-lambda"
        }
        # (5 unchanged attributes hidden)
    }

  # module.vpc.aws_route_table.private[1] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + cidr_block                 = "0.0.0.0/0"
              + nat_gateway_id             = (known after apply)
                # (11 unchanged attributes hidden)
            },
        ]
      + tags             = {
          + "Environment" = "dev"
          + "Name"        = "hello-world-lambda-private-rt-2-dev"
          + "Project"     = "hello-world-lambda"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "hello-world-lambda-private-rt-2-dev"
          + "Project"     = "hello-world-lambda"
        }
      + vpc_id           = "vpc-0f68bdafcaaac61ff"
    }

  # module.vpc.aws_route_table_association.private[1] will be updated in-place
  ~ resource "aws_route_table_association" "private" {
        id             = "rtbassoc-0a080e637e17f2075"
      ~ route_table_id = "rtb-01ef08488f586f1f7" -> (known after apply)
        # (2 unchanged attributes hidden)
    }

Plan: 5 to add, 4 to change, 0 to destroy.
