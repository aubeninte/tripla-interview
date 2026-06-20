resource "aws_s3_bucket" "this" {
  bucket        = "${var.project_name}-${var.environment}-static-assets"
  force_destroy = var.environment != "prod" # Prevent accidental production deletion

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # Default blocking the public access - best security practice
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}