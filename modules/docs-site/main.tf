# Simple S3 static website for workshop documentation
# This creates a public S3 bucket with the architecture diagram

variable "bucket_name" {
  description = "Name for the S3 bucket (must be globally unique)"
  type        = string
  default     = "eck-workshop-docs"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "workshop"
}

# S3 Bucket
resource "aws_s3_bucket" "docs" {
  bucket = "${var.bucket_name}-${var.environment}"

  tags = {
    Name        = "ECK Workshop Docs"
    Environment = var.environment
  }
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Make bucket public
resource "aws_s3_bucket_public_access_block" "docs" {
  bucket = aws_s3_bucket.docs.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read
resource "aws_s3_bucket_policy" "docs" {
  bucket = aws_s3_bucket.docs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.docs.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.docs]
}

# Upload the architecture diagram
resource "aws_s3_object" "architecture" {
  bucket       = aws_s3_bucket.docs.id
  key          = "index.html"
  source       = "${path.module}/../../docs/architecture-diagram.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../../docs/architecture-diagram.html")
}

# Outputs
output "website_url" {
  description = "URL of the documentation website"
  value       = "http://${aws_s3_bucket.docs.bucket}.s3-website.${data.aws_region.current.name}.amazonaws.com"
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.docs.bucket
}

data "aws_region" "current" {}
