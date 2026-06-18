# Generator framework using jinja
from jinja2 import Template

# Keeps templates decoupled from application logic
S3_TEMPLATE = """
provider "aws" {
  region = "{{ aws_region }}"
}

resource "aws_s3_bucket" "this" {
  bucket = "{{ bucket_name }}"
}

{% if acl == "private" %}
# Private acl configuration https://docs.aws.amazon.com/AmazonS3/latest/userguide/managing-acls.html
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this,
  ]

  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}
{% else %}
# Default ACL
resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "{{ acl }}"
}
{% endif %}
"""

class TerraformGenerator:
    @staticmethod
    def generate_s3_config(aws_region: str, bucket_name: str, acl: str) -> str:
        """Renders the S3 Jinja2 template into a valid Terraform string."""
        template = Template(S3_TEMPLATE)
        rendered = template.render(
            aws_region=aws_region,
            bucket_name=bucket_name,
            acl=acl
        )
        return rendered.strip()