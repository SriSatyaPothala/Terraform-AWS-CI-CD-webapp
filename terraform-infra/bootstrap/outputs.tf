output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_s3_bucket.bucket
  description = "Terraform state bucket name"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_lock.name
  description = "Terraform lock table name"
}

output "kms_key_arn" {
  value       = aws_kms_key.s3_bucket_kms_key.arn
  description = "KMS key ARN used for encryption"
}

output "ec2_key_name" {
  value       = aws_key_pair.ec2.key_name
  description = "Name of the EC2 key pair"
}

output "ami_id" {
  value       = data.aws_ami.ubuntu.id
  description = "AMI ID stored in SSM"
}


