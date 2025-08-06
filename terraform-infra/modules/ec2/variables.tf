variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Auto Scaling Group"
}

variable "alb_target_group_arn" {
  type        = string
  description = "Target Group ARN for attaching ASG to ALB"
}
