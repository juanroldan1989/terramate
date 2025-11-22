locals {
  aws_region = "us-east-1"
  is_primary_region = true

  # Disaster recovery pairing
  dr_region = "us-west-1"

  availability_zones = ["us-east-1a", "us-east-1b"]

  vpc_cidrs = {
    vpc-1 = "10.0.0.0/16"
    vpc-2 = "10.1.0.0/16"
  }
}
