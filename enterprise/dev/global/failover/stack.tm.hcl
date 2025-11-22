stack {
  name        = "failover"
  description = "failover"
  after       = ["/enterprise/dev/us-east-1/03-applications/service-a", "/enterprise/dev/us-west-1/03-applications/service-a"]
  id          = "23950209-479c-40e3-b5bf-9eb13cee49c3"
}
