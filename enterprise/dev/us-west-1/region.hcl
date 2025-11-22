locals {
  aws_region = "us-west-1"
  is_primary_region = false

  # Disaster recovery pairing
  dr_region = "us-east-1"

  availability_zones = ["us-west-1a", "us-west-1c"]

  vpc_cidrs = {
    vpc-1 = "10.0.0.0/16"
    vpc-2 = "10.1.0.0/16"
  }
}
