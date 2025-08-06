#!/bin/bash

REGION="ap-south-1"
ECR_REPO_URI="$(aws ssm get-parameter --name "/dev/ecr_repo_uri" --with-decryption --region $REGION --query 'Parameter.Value' --output text)"

# Authenticate to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

# Pull latest image
docker pull $ECR_REPO_URI:latest
