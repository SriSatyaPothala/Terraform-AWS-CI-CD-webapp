#!/bin/bash

APP_NAME="nginx-app"
REGION="ap-south-1"
PORT=80

ECR_REPO_URI="$(aws ssm get-parameter --name "/dev/ecr_repo_url" --with-decryption --region $REGION --query 'Parameter.Value' --output text)"

# Start new container
docker run -d --name $APP_NAME -p $PORT:80 $ECR_REPO_URI:latest
