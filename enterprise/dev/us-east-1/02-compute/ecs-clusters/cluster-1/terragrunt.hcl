include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/ecs/cluster"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  # compute layer common configuration
  aws_account_id = local.account_vars.locals.aws_account_id
  aws_region     = local.region_vars.locals.aws_region
  env            = local.account_vars.locals.environment
  layer          = "compute"

  # cluster specific configuration
  cluster_name   = "cluster-1"
}
