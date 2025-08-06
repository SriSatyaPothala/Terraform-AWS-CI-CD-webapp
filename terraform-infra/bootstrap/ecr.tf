# Fetch the KMS Key ARN from SSM Parameter Store
data "aws_ssm_parameter" "kms_key_arn" {
  name = "/${var.environment}/kms_key_arn"
}

# Create ECR Repository
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.project}-ecr"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_ssm_parameter.kms_key_arn.value
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Name        = "${var.project}-ecr"
  }
}

# Store the repository URL in SSM Parameter Store for reuse
resource "aws_ssm_parameter" "ecr_repo_url" {
  name  = "/${var.environment}/ecr_repo_url"
  type  = "String"
  value = aws_ecr_repository.ecr.repository_url
}

# Store the repository name too (can be used in CodeBuild)
resource "aws_ssm_parameter" "ecr_repo_name" {
  name  = "/${var.environment}/ecr_repo_name"
  type  = "String"
  value = aws_ecr_repository.ecr.name
}
