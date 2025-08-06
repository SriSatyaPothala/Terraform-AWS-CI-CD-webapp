data "aws_ssm_parameter" "kms_key_arn" {
  name = "/${var.environment}/kms_key_arn"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.project}-${var.environment}-artifact-bucket"

  tags = {
    Name        = "${var.project}-${var.environment}-artifact-bucket"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_s3_bucket_versioning" "artifact_bucket_versioning" {
  bucket = aws_s3_bucket.artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_bucket_encryption" {
  bucket = aws_s3_bucket.artifact_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_ssm_parameter.kms_key_arn.value
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifact_bucket_block" {
  bucket = aws_s3_bucket.artifact_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
