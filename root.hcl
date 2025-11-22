# This root.hcl file is setup for "enterprise" architecture handling multiple accounts and regions.

## Notes:
## - S3 bucket name includes AWS account ID and region to ensure uniqueness across multiple accounts and regions.
## - DynamoDB table name includes AWS account ID to ensure uniqueness across multiple accounts.

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "enterprise-terraform-state-${local.aws_account_id}-${local.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "enterprise-terraform-state-locks-${local.aws_account_id}"
  }
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  aws_provider_version = local.account_vars.locals.aws_provider_version
  aws_account_id       = local.account_vars.locals.aws_account_id
  aws_region           = local.region_vars.locals.aws_region
  env                  = local.account_vars.locals.environment
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Environment = "${local.env}"
      CostCenter  = "AWS Billing"
      ManagedBy   = "Terraform"
      Owner       = "Platform Team"
      Project     = "terramate-infrastructure"
    }
  }
}
EOF
}

generate "terraform" {
  path      = "required_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> ${local.aws_provider_version}"
    }
  }
}
EOF
}
