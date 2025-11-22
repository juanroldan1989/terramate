include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/networking"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  # networking layer common configuration
  aws_account_id = local.account_vars.locals.aws_account_id
  aws_region     = local.region_vars.locals.aws_region
  env            = local.account_vars.locals.environment
  layer          = "networking"

  # VPC-specific configuration
  vpc_cidr = local.region_vars.locals.vpc_cidrs["vpc-1"]
  zone1    = local.region_vars.locals.availability_zones[0]
  zone2    = local.region_vars.locals.availability_zones[1]
}
