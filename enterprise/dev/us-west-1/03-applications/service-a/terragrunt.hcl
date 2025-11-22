include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/ecs/external-service"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "networking" {
  config_path = find_in_parent_folders("01-networking/vpc-1")
  mock_outputs = {
    vpc_id                = "vpc-12345678"
    private_subnet_ids    = ["subnet-11111111", "subnet-22222222"]
    public_subnet_ids     = ["subnet-33333333", "subnet-44444444"]
  }
}

dependency "cluster" {
  config_path = find_in_parent_folders("02-compute/ecs-clusters/cluster-1")
  mock_outputs = {
    cluster_id = "arn:aws:ecs:us-west-1:123456789012:cluster/cluster-1"
  }
}

inputs = {
  # applications layer common configuration
  aws_account_id = local.account_vars.locals.aws_account_id
  aws_region     = local.region_vars.locals.aws_region
  env            = local.account_vars.locals.environment

  # service-specific configuration
  vpc_id         = dependency.networking.outputs.vpc_id
  subnet_ids     = dependency.networking.outputs.private_subnet_ids  # ECS tasks in private subnets
  alb_subnet_ids = dependency.networking.outputs.public_subnet_ids   # ALB in public subnets
  ecs_cluster_id = dependency.cluster.outputs.cluster_id
  service_name   = "service-a"
  app_name       = "app-a"
  container_name = "app-a"
}
