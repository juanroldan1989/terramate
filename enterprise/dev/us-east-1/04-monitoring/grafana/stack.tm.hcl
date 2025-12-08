stack {
  name        = "grafana"
  description = "grafana"
  after       = ["/enterprise/dev/us-east-1/01-networking/vpc-1", "/enterprise/dev/us-east-1/02-compute/ecs-clusters/cluster-1"]
  id          = "e7b39bf7-7ff5-4d1b-8d3b-7ae7f862c585"
}
