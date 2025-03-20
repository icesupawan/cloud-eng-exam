output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "cloudfront_oai_arn" {
  value = aws_cloudfront_origin_access_identity.this.iam_arn
}
