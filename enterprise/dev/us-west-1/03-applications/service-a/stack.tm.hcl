stack {
  name        = "service-a"
  description = "service-a"
  after       = ["/enterprise/dev/us-west-1/01-networking/vpc-1", "/enterprise/dev/us-west-1/02-compute/ecs-clusters/cluster-1"]
  id          = "974b6ba3-beb2-449b-a45b-268a6598bd5a"
}
