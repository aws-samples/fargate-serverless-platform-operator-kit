variable "bucket_name" {
  type        = string
  description = "The S3 bucket name"
}

variable "kms_key_name" {
  type        = string
  description = "The S3 KMS encryption key name"
}