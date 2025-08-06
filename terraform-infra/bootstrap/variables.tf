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
