variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, prod)"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "alb_name" {
  type        = string
  description = "Full AWS ALB name (not just Terraform name)"
}

variable "asg_name" {
  type        = string
  description = "Auto Scaling Group name"
}
