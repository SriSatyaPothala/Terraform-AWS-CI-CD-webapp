#!/bin/bash
set -e

REGION="ap-south-1"
echo "Starting pull-image.sh script..."
IMAGE_TAG=$(cat /home/ubuntu/app/nginx-app/imageTag.txt)
echo "Image tag from file is: $IMAGE_TAG"

ECR_REPO_URI="$(aws ssm get-parameter --name "/dev/ecr_repo_url" --with-decryption --region "$REGION" --query 'Parameter.Value' --output text)"
if [ -z "$ECR_REPO_URI" ]; then
    echo "ERROR: ECR_REPO_URI variable is empty. Failed to retrieve from SSM."
    exit 1
fi
echo "ECR URI from SSM is: $ECR_REPO_URI"

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ECR_REPO_URI"
# Capture the exit code of the docker login command
LOGIN_EXIT_CODE=$?
if [ $LOGIN_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Docker login failed with exit code $LOGIN_EXIT_CODE"
  exit 1
fi
echo "Docker login succeeded."

# Pull latest image
docker pull "$ECR_REPO_URI:$IMAGE_TAG"
# Capture the exit code of the docker pull command
PULL_EXIT_CODE=$?
if [ $PULL_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Docker Pull failed with exit code $PULL_EXIT_CODE for image: $ECR_REPO_URI:$IMAGE_TAG"
  exit 1
fi
echo "Docker pull succeeded."

echo "Script completed successfully."
exit 0