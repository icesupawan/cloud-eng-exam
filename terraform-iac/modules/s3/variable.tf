variable "bucket_name" {
  description = "S3 Bucket Name"
  type        = string
}

variable "allowed_origins" {
  description = "Allowed CORS Origins"
  type        = list(string)
  default     = ["*"]
}

variable "user_upload_iam_arn" {
  type        = string
}
variable "upload_role" {
  type        = string
}
