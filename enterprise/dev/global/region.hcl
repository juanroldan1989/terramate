locals {
  # Primary region for storing global resource state
  aws_region = "us-east-1"  # Use your primary region

  # Mark this as global configuration
  is_global_component = true

  # Global components don't need AZs, but keep for consistency
  availability_zones = ["us-east-1a", "us-east-1b"]

  # No VPC CIDRs needed for global components
  vpc_cidrs = {}
}
