#!/bin/bash
# enterprise/scripts/dr-test.sh

DOMAIN="service-a-dev.automata-labs.nl"
PRIMARY_CLUSTER="dev-us-east-1-cluster-1"
SERVICE_NAME="ecs-service"

echo "🧪 Starting DR Test for Service-A"

# 1. Verify both regions are healthy
echo "1. Testing primary region..."
# curl -f http://$DOMAIN/health || echo "❌ Primary unhealthy"
curl -f http://$DOMAIN || echo "❌ Primary unhealthy"

# 2. Simulate failure
echo "2. Simulating primary region failure ..."

echo "   Current Primary ECS running count:"
aws ecs describe-services \
    --cluster $PRIMARY_CLUSTER \
    --services $SERVICE_NAME \
    --region us-east-1 \
    --query 'services[0].runningCount' \
    --output text

echo "   Scaling down primary ECS service to 0 to simulate failure..."
aws ecs update-service \
    --cluster $PRIMARY_CLUSTER \
    --service $SERVICE_NAME \
    --desired-count 0 \
    --region us-east-1

echo "   Primary ECS service scaled down."

echo "   Waiting for primary ECS service to stabilize..."
aws ecs wait services-stable \
    --cluster $PRIMARY_CLUSTER \
    --services $SERVICE_NAME \
    --region us-east-1

echo "   Current Primary ECS running count:"
aws ecs describe-services \
    --cluster $PRIMARY_CLUSTER \
    --services $SERVICE_NAME \
    --region us-east-1 \
    --query 'services[0].runningCount' \
    --output text

# # Method 2: Fail ALB health checks
# # Update target group to mark all targets unhealthy

# # Method 3: Block ALB traffic with security group
# aws ec2 authorize-security-group-ingress \
# --group-id sg-xxxxx \
# --protocol tcp \
# --port 80 \
# --source-group sg-block-all
# ```

# 3. Wait for failover
echo "3. Waiting for Route 53 failover (up to 3 minutes)..."
for i in {1..180}; do
    echo "Checking... ($i/180)"
    if curl -f http://$DOMAIN >/dev/null 2>&1; then
        echo "✅ Failover successful!"
        break
    fi
    sleep 1
done

# 4. Test DR region is serving traffic
echo "4. Testing failover..."
curl -f http://$DOMAIN && echo "✅ DR working"

# 5. Restore primary
echo "5. Restoring primary region..."
aws ecs update-service \
    --cluster $PRIMARY_CLUSTER \
    --service $SERVICE_NAME \
    --desired-count 1 \
    --region us-east-1

echo "   Primary ECS service scaled back up."

echo "   Waiting for primary ECS service to stabilize..."
aws ecs wait services-stable \
    --cluster $PRIMARY_CLUSTER \
    --services $SERVICE_NAME \
    --region us-east-1

echo "   Current Primary ECS running count:"
aws ecs describe-services \
    --cluster $PRIMARY_CLUSTER \
    --services $SERVICE_NAME \
    --region us-east-1 \
    --query 'services[0].runningCount' \
    --output text

# 6. Verify primary region is healthy again
echo "6. Verifying primary region health..."
curl -f http://$DOMAIN/health && echo "✅ Primary restored"

echo "🎉 DR Test Complete"
