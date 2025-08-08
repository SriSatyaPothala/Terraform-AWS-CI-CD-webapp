# Automated Nginx Application Deployment Using Terraform and AWS CI/CD Stack

## Project Overview
This project demonstrates a fully automated CI/CD pipeline to provision infrastructure and deploy a sample Dockerized web application on AWS using Terraform and AWS native DevOps services.

The pipeline is designed for high availability, idempotency, rollback capability - implements a blue/green deployment strategy minimizing downtime.

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
    - git clone **url**
    - cd **repo**
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
    1. Plan & Docker Build Project – Runs terraform plan, and cost estimation report, saves the plan to S3 artifact ,builds Docker image, pushes to ECR. This project uses **buildspec-tfplan.yml** present in aws-devops/scripts/ folder
    Note: I have used a third-party tool called infracost, register in the application and get the API key and add the API key to SSM parameter store which will be fetched by codebuild .
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
- High Availability Setup 
    - This project ensures fault tolerance and high availability across AWS services:
    - Mutli-AZ Deployment
        - VPC is configured with public and private subnets across two Availability Zones
        - Application resources are spread evenly across AZs to reduce the risk of downtime.
    - Load Balancing
        - An application Load Balancer distributes incoming requests across EC2 instances in multiple AZs
    - AutoScaling Group
        - Ensures the application automatically scales out to handle traffic spikes and scales in to save costs during low demand. Minimum : 2 , Maximum : 4
        - Replaces unhealthy instances automatically.
    - NAT Gateways in multiple AZs
        - Each private subnet has a dedicated NAT Gateway in a separate AZ for redundancy.
- Application - Simple Nginx serving static content
- CI/CD pipeline using:
    - CodePipeline: orchestrates the build,approval,deployment stages
    - CodeBuild: 2 codebuild projects are created
        - Build #1: Runs terraform plan, creates a terraform cost estimation plan& pushes Docker image to ECR, stores plan and cost estimation as plain .txt file  in S3
        - Build #2: Runs terraform apply after manual approval 
    - CodeDeploy: Deploys app to EC2 instances using blue/green deployment
    - Cloudwatch & Lambda:  Monitors deployment and triggers lambda function and logs to cloudwatch in case of pipeline failure
- Blue/Green deployment with CodeDeploy:
    - New versions of the application are deployed to a separate environment.
    - Traffic is only switched after successful health checks, ensuring no downtime during releases.
    - Automatic rollback is enabled if health checks fail.

- Monitoring, Alerts & Automated Failure Handling
    - ALB 5XX Error Alarm: Monitors Application Load Balancer for 5XX HTTP errors.Triggers an alert if errors exceed the threshold within the evaluation period.
    - ASG Desired Capacity Alarm :Ensures the Auto Scaling Group maintains the expected number of instances.
    - Automated CI/CD Failure Handling: EventBridge Rule listens for AWS CodePipeline failure events.When a failure is detected, it invokes a Lambda function (name and ARN retrieved from SSM Parameter Store).The Lambda can log details.

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

## Additional Resources
- [Infracost](https://www.infracost.io/) – Tool to estimate cloud costs from your Terraform projects before you deploy.
- Reference Screenshots available at setup-screenshots