#!/bin/bash

REGION="ap-south-1"
IMAGE_TAG=$(cat /home/ubuntu/app/nginx-app/imageTag.txt)
ECR_REPO_URI="$(aws ssm get-parameter --name "/dev/ecr_repo_url" --with-decryption --region $REGION --query 'Parameter.Value' --output text)"
# Exit if the ECR URI variable is empty
if [ -z "$ECR_REPO_URI" ]; then
    echo "ERROR: ECR_REPO_URI variable is empty. Failed to retrieve from SSM."
    exit 1
fi

# Authenticate to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URI || {
    echo "ECR Login failed"; exit 1;
}


# Pull latest image
docker pull "$ECR_REPO_URI:$IMAGE_TAG" || {echo "Docker Pull failed for image: $ECR_REPO_URI:$IMAGE_TAG"; exit 1; 
}
