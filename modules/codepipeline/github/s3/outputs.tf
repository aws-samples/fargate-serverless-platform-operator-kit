output "bucket_arn" {
  description = "The S3 bucket ARN"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_key_arn" {
  description = "The KMS key id"
  value       = aws_kms_key.bucket_encryption_key.arn
}

output "bucket_name" {
  description = "The S3 bucket name"
  value       = aws_s3_bucket.bucket.bucket
}