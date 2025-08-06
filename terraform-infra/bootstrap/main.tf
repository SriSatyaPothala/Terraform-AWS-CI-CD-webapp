terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}
# KMS Key
resource "aws_kms_key" "s3_bucket_kms_key" {
  description             = "CMK to encrypt Terraform state in S3"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "terraform-kms-policy",
    Statement: [
      {
        Sid: "EnableAccountAccess",
        Effect = "Allow",
        Principal = {
          AWS: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "kms:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "alias" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.s3_bucket_kms_key.key_id
}

# S3 bucket
resource "aws_s3_bucket" "terraform_s3_bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = false

  tags = {
    Name        = "terraform-state-bucket"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.terraform_s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.terraform_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_bucket_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket                  = aws_s3_bucket.terraform_s3_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# DynamoDB Table
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-lock-table"
    Environment = var.environment
  }
}

# EC2 Key Pair
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2" {
  key_name   = "${var.environment}-ec2-key"
  public_key = tls_private_key.ec2.public_key_openssh
}

# Get latest Ubuntu AMI (optional: customize filter)
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# SSM Parameters
resource "aws_ssm_parameter" "kms_key_arn" {
  name  = "/${var.environment}/kms_key_arn"
  type  = "SecureString"
  value = aws_kms_key.s3_bucket_kms_key.arn
}

resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "/${var.environment}/s3_bucket_name"
  type  = "SecureString"
  value = aws_s3_bucket.terraform_s3_bucket.bucket
}

resource "aws_ssm_parameter" "dynamodb_table_name" {
  name  = "/${var.environment}/dynamodb_table_name"
  type  = "SecureString"
  value = aws_dynamodb_table.terraform_lock.name
}

resource "aws_ssm_parameter" "ec2_private_key" {
  name  = "/${var.environment}/ec2_private_key"
  type  = "SecureString"
  value = tls_private_key.ec2.private_key_pem
}

resource "aws_ssm_parameter" "ec2_key_name" {
  name  = "/${var.environment}/ec2_key_pair_name"
  type  = "String"
  value = aws_key_pair.ec2.key_name
}

resource "aws_ssm_parameter" "ami_id" {
  name  = "/${var.environment}/ami_id"
  type  = "String"
  value = data.aws_ami.ubuntu.id
}
# s3 bucket for artifact storage
module "s3" {
  source      = "../modules/s3"
  project     = var.project
  environment = var.environment
}
