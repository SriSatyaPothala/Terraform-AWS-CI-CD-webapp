output "artifact_bucket_name" {
  description = "The name of the artifact S3 bucket"
  value       = aws_s3_bucket.artifact_bucket.id
}
