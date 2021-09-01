# janus-gateway
Host Janus using docker. Supports  boringSSL, Data channel, and basic plugin support. 

To host on ECS: 

1. **ECR Steps**
- Create ECR reopository
- Build the image and push to ECR

2. **ECS Steps**
- Create VPC Cluster 
- Create a service, provide port mapping for container
- Update the security group (Inbound rules)

3. API Gateway
- WIP

