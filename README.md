# Host Janus using docker. Supports boringSSL, Data channel, and Textroom and other basic plugin support. 

To host on ECS: 

1. **ECR**
- Create ECR reopository
- Build the image and push to ECR

2. **ECS**
- Create VPC Cluster 
- Create a service, provide port mapping for container
- Update the security group (Inbound rules)

3. **API Gateway**
- WIP
