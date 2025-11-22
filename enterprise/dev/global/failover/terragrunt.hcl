include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/route53/failover"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

dependency "primary_service_a" {
  config_path = find_in_parent_folders("us-east-1/03-applications/service-a")
}

dependency "dr_service_a" {
  config_path = find_in_parent_folders("us-west-1/03-applications/service-a")
}

inputs = {
  aws_account_id = local.account_vars.locals.aws_account_id
  env            = local.account_vars.locals.environment

  # DNS configuration
  domain_name = "service-a-dev.automata-labs.nl"
  hosted_zone_id = "Z045481634IZ1D09Y7YO5"  # Your Route 53 hosted zone

  # Primary record (us-east-1)
  primary_record = {
    name    = "service-a-dev.automata-labs.nl"
    type    = "A"
    alias = {
      name                   = dependency.primary_service_a.outputs.service_url
      zone_id                = dependency.primary_service_a.outputs.alb_zone_id
      evaluate_target_health = true
    }
    set_identifier = "primary"
    failover_routing_policy = {
      type = "PRIMARY"
    }
  }

  # DR record (us-west-1)
  dr_record = {
    name    = "service-a-dev.automata-labs.nl"
    type    = "A"
    alias = {
      name                   = dependency.dr_service_a.outputs.service_url
      zone_id                = dependency.dr_service_a.outputs.alb_zone_id
      evaluate_target_health = true
    }
    set_identifier = "secondary"
    failover_routing_policy = {
      type = "SECONDARY"
    }
  }

  # Health check for primary region
  health_check = {
    fqdn                            = dependency.primary_service_a.outputs.service_url
    port                            = 80
    type                            = "HTTP"
    resource_path                   = "/"
    failure_threshold               = 3
    request_interval                = 30
    cloudwatch_alarm_region         = "us-east-1"
    cloudwatch_alarm_name           = "service-a-primary-health"
    insufficient_data_health_status = "Healthy"
  }
}
