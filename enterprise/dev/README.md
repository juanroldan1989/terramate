# DEV Environment

![alt text](<../../zdocs/screenshots/dev-environment.png>)

## Global Services

- **Route53 Hosted Zone**: automata-labs.nl
- **DNS Failover Configuration**:
  - **PRIMARY**: service-a-dev.automata-labs.nl → us-east-1 ALB
  - **SECONDARY**: service-a-dev.automata-labs.nl → us-west-1 ALB
- **Health Check**: Monitors the us-east-1 ALB on port 80 (HTTP /)

## US-EAST-1 Region (PRIMARY)

- **VPC**: dev-us-east-1-vpc-main (10.0.0.0/16)
- **Multi-AZ**: us-east-1a and us-east-1b
- **Internet Gateway** + NAT Gateway
- **Application Load Balancer**: dev-us-east-1-app-a-alb (monitored by health check)
- **ECS Cluster**: dev-us-east-1-cluster-1
  - AZ us-east-1a: Fargate tasks in private subnet (10.0.0.0/19)
  - AZ us-east-1b: Fargate tasks in private subnet (10.0.32.0/19)
- NAT Gateway for outbound traffic
- **Private Subnets**: ECS tasks running in isolated subnets

## US-WEST-1 Region (SECONDARY)

- **VPC**: dev-us-west-1-vpc-main (10.0.0.0/16)
- **Multi-AZ**: us-west-1a and us-west-1c
- **Internet Gateway** + NAT Gateway
- **Application Load Balancer**: dev-us-west-1-app-a-alb
- **ECS Cluster**: dev-us-west-1-cluster-1
  - AZ us-west-1a: Fargate tasks in private subnet (10.0.0.0/19)
  - AZ us-west-1c: Fargate tasks in private subnet (10.0.32.0/19)
- NAT Gateway for outbound traffic
- **Private Subnets**: ECS tasks running in isolated subnets

## Traffic Flow Architecture

### Inbound Traffic Management

1. **DNS Resolution**: Client requests are resolved through Route53 hosted zone
2. **Primary Routing**: Route53 directs traffic to PRIMARY endpoint (us-east-1) when health checks are successful
3. **Failover Mechanism**: Automatic failover to SECONDARY endpoint (us-west-1) occurs when primary region health checks fail
4. **Request Processing**: Traffic is routed via Internet Gateway → Application Load Balancer → ECS Fargate Tasks

### Outbound Connectivity

- **Internet Access**: ECS Fargate tasks utilize NAT Gateway for secure outbound internet connectivity
- **Network Isolation**: All outbound traffic is routed through designated NAT Gateway infrastructure

### Health Monitoring & Observability

- **Failover Decision Engine**: Automated health checks continuously monitor us-east-1 Application Load Balancer
- **Service Availability**: Health check endpoints validate service responsiveness for DNS failover operations

## High Availability Features

- Multi-region deployment with automatic DNS failover
- Multi-AZ deployment within each region
- Health checks monitoring primary region
- Fargate for serverless container orchestration