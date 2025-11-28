#!/bin/bash
# Script that runs on EC2 boot via user_data

set -e
exec > /var/log/user-data.log 2>&1

AWS_REGION="us-east-1"

# This is the ONLY Terraform placeholder
ECR_REPO_URL="${ecr_repository_url}"

echo "Starting user_data"
echo "Using ECR repo: $ECR_REPO_URL"

# Make sure docker is running
sudo systemctl enable docker || true
sudo systemctl start docker || true

# Login to ECR using instance IAM role
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REPO_URL"

# Pull latest image
docker pull "$ECR_REPO_URL:latest"

# Clean up any old container
if [ "$(docker ps -aq -f name=webapp)" ]; then
  docker stop webapp || true
  docker rm webapp || true
fi

# Run the container
docker run -d \
  --name webapp \
  --restart unless-stopped \
  -p 80:80 \
  "$ECR_REPO_URL:latest"

echo "user_data complete"
