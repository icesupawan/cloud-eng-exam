module "secure_s3" {
  source               = "./modules/s3"
  bucket_name          = "${var.name}-user-upload-bucket"
  allowed_origins      = ["https://www.myfrontend.ice.com"]
  user_upload_iam_arn  = aws_iam_user.upload_user.arn
  upload_role          = aws_iam_role.upload_role.arn
}
resource "aws_iam_user" "upload_user" {
  name = "${var.name}-user-upload-s3-user"
}

resource "aws_iam_access_key" "upload_user_access_key" {
  user = aws_iam_user.upload_user.name
}

# IAM Role for user uploads (Presigned URL)
resource "aws_iam_role" "upload_role" {
  name = "${var.name}-user-upload-bucket-upload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.upload_user.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "upload_policy" {
  name        = "${var.name}-user-upload-bucket-upload-policy"
  description = "Allow user uploads"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.name}-user-upload-bucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "upload_attach" {
  role       = aws_iam_role.upload_role.name
  policy_arn = aws_iam_policy.upload_policy.arn
}
resource "aws_iam_policy" "presigned_url_policy" {
  name        = "${var.name}-user-presigned-url-policy"
  description = "Allow creating presigned URLs for S3 uploads"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "arn:aws:s3:::${var.name}-user-upload-bucket/*"
      }
    ]
  })
}
  module "secure_s3_log_group" {
  source = "./modules/cloudwatch_loggroup"
  log_group_name = "/s3/${var.name}-user-upload-bucket"
  retention_in_days = 7
}