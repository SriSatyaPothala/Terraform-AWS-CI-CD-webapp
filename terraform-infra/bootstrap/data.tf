# data.tf

# To fetch AWS account ID
data "aws_caller_identity" "current" {}

# To get KMS Key ARN from SSM Parameter Store
data "aws_ssm_parameter" "kms_key" {
  name = "/${var.environment}/kms_key_arn"
}

# Local value 
locals {
  kms_key_arn = data.aws_ssm_parameter.kms_key.value
}
