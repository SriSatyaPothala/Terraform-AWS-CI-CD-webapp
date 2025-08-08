# Automated Nginx Application Deployment Using Terraform and AWS CI/CD Stack

## Project Overview
This project demonstrates a fully automated CI/CD pipeline to provision infrastructure and deploy a sample Dockerized web application on AWS using Terraform and AWS native DevOps services.

The pipeline is designed for high availability, idempotency, rollback capability - implements a blue/green deployment strategy minimizing downtime.

## Key Highlights
- Infrastructure Provisioning using Terraform in two stages:
    - Bootstrap Stage(/terraform-infra/bootstrap) - creates foundational resources (run them locally)
    - S3 bucket for terraform state
    - S3 bucket for artifact storage
    - Dynamodb table for Terraform state locking
    - KMS key for encryption (stored in ssm parameter stored and used across various resources encryption )
    - ECR repository for Docker images
    - SSM parameter store entries 
    - IAM roles/policies for CI/CD

- Environment Stage(/terraform-infra/envs/dev) - Creates Application infrastructure:
    - VPC (multi-AZ) with public/private subnets
    - Security groups, NAT Gateway
    - Application Load Balancer
    - Auto Scaling Group with EC2 instances (launch templates) and User data scripts 
    - CloudWatch alarms and logs
- Application - Simple Nginx serving static content
- CI/CD pipeline using:
    - CodePipeline: orchestrates the build,approval,deployment stages
    - CodeBuild: 2 codebuild projects are created
        - Build #1: Runs terraform plan, builds & pushes Docker image to ECR, stores plan in S3
        - Build #2: Runs terraform apply after manual approval 
    - CodeDeploy: Deploys app to EC2 instances using blue/green deployment
    - Cloudwatch & Lambda:  Monitors deployment and triggers lambda function and logs to cloudwatch in case of pipeline failure

## Prerequisites
- Ensure you have:
    - AWS Account with admin permissions
    - AWS CLI installed and configured
    - Terraform v1.5+ installed locally
    - Git installed
    - Permissions to create and manage: S3, DynamoDB, IAM, ECR, CodePipeline, CodeBuild, CodeDeploy
    GitHub repository (or S3) for source code storage
    - Docker installed locally (for initial image build/testing)

## Setup Instructions
1. Clone the repository
    - git clone <url>
    - cd <repo>
2. Run Bootstrap Terraform
    - cd terraform-infra/bootstrap
    - terraform init  
    - terraform plan -var-file=<your-values.tfvars >
    - terraform apply -var-file=<your-values.tfvars>
    - This will create :S3 bucket for Terraform state storage,S3 bucket for artifacts,DynamoDB table for state locking,KMS encryption key,ECR repository,IAM roles,SSM parameters.
    - Note:
    1. Kindly check varibales.tf for the values needed to run the bootstrap module.
    2. After successful creation of the resources, store the statefile remotely into the S3 bucket created for terraform state.
3. Configure CI/CD
    - Create two CodeBuild projects in AWS Console:
    1. Plan & Docker Build Project – Runs terraform plan, saves the plan to S3 artifact ,builds Docker image, pushes to ECR. This project uses **buildspec-tfplan.yml** present in aws-devops/scripts/ folder
    2. Apply Project – Runs terraform apply after Manual approval. This project uses **buildspec-tfapply.yml** present in aws-devops/scripts/ folder 
    3. Configure Codepipeline with:
        - source stage: GitHub or S3 trigger
        - Build stage: Plan & Docker Build (Here configure codebuild environmental variable DOCKERHUB_USERNAME as codebuild needs it to pull base image from the dockerhub registry)
        - Approval stage: Manual Approval, Review the plan in the S3 bucket(from the URL displayed on the console and give comments accordingly)
        - Apply Stage: codebuild for applying terraform apply 
        - Deploy stage: CodeDeploy blue/green deployment.
        Note: Codebuild, codepipeline IAM permissiosn need to be set up properly to pull the .tfvars file from SSM parameter store.

## How to Trigger Deployments
- Push changes to the mainbranch (or configured branch in CodePipeline)
- CodePipeline will:
    1. Pull source code 
    2. Run Build #1 (terraform plan + Docker build + ECR push)
    3. Wait for Manual Approval
    4. Run Build #2 (Terraform Apply)
    5. Pass artifacts to CodeDeploy for deployment to EC2 instances.
- Deployment updates will be routed via the Application Load Balancer

## Rollback Approach
- CodeDeploy Blue/Green Rollback:
    - If health check fails, Codedeploy automatically routes traffic back to the last working environment.
    - previous application version remains available until the new deployment is confirmed healthy.
- Terraform Rollback:
    - Apply the previous terraform plan stored in S3 artifacts to revert to last known good infrastructure state.
- Cloudwatch + Lambda
    - Lamda function gets triggered from eventbridge whenever there is a failure during pipeline execution.
    - Lambda function collects pipeline failure logs from codepipeline and sends logs to cloudwatch. (can be further optimized to send email alerts)
    Note: Lambda function is attached in scripts section of the folder , but it was manually created from AWS console. So use the script provided to create lambda function.

        