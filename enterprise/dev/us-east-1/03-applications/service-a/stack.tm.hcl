stack {
  name        = "service-a"
  description = "service-a"
  after       = ["/enterprise/dev/us-east-1/01-networking/vpc-1", "/enterprise/dev/us-east-1/02-compute/ecs-clusters/cluster-1"]
  id          = "e0e4a31a-5dd5-474a-b64a-0761acd93101"
}
