variable "aws_region" {
  description = "AWS Region"
  type        = string
}
variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}
variable "project" {
  description = "Project name"
  type        = string
}
variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to store Terraform state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table for Terraform locking"
}
variable "ubuntu_ami_id" {
  type        = string
  description = "Fixed Ubuntu 20.04 AMI ID for ap-south-1"
  default     = "ami-06cc5ebfb8571a147" # replace the version with the one that is desired 
}
