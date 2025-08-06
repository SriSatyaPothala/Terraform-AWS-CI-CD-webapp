variable "environment" {
  description = "Environment name (e.g. dev, qa, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names (e.g. project name)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}
variable "project" {
  type        = string
  description = "Project prefix (e.g. myapp)"   
}
variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}
variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function for pipeline failure"
}

variable "lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function for pipeline failure"
}
