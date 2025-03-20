resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = var.allowed_origins
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_logging" "upload_bucket_logging" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.logging.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket" "logging" {
  bucket = "logging"
}
resource "aws_cloudfront_origin_access_identity" "this" {}

resource "aws_s3_bucket_policy" "upload_bucket_policy" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = var.upload_role
        },
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      },

      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.this.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      },
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.this.id}",
          "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

