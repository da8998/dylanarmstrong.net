terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

variable "zone" {
  type    = string
  default = "Z03876303CS15DF1QAT82"
}

resource "aws_s3_bucket" "web_bucket" {
  bucket = "dylanarmstrong-net-website-content"
  tags = {
    Name = "dylanarmstrong-net-website-content"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "web_bucket_versioning" {
  bucket = aws_s3_bucket.web_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "web_bucket_website_config" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.web_bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
	    "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": [
        "${aws_s3_bucket.web_bucket.arn}",
        "${aws_s3_bucket.web_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_route53_record" "root" {
  zone_id = var.zone
  name    = "dylanarmstrong.net"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dylanarmstrong_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.dylanarmstrong_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "default" {
  provider          = aws.virginia
  domain_name       = "dylanarmstrong.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  name    = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_type
  zone_id = var.zone
  records = [tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_value]
  ttl     = "300"
}

resource "aws_acm_certificate_validation" "default_validate" {
  timeouts {
    create = "5m"
  }

  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [aws_route53_record.validation.fqdn]
}


resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "dylanarmstrong_distribution" {
  enabled = true
  aliases = ["dylanarmstrong.net"]
  default_root_object = "index.html"
  origin {
    domain_name = aws_s3_bucket.web_bucket.bucket_regional_domain_name
    origin_id   = "primaryS3"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id = "primaryS3"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    ssl_support_method  = "sni-only"
    acm_certificate_arn = aws_acm_certificate.default.arn
  }
}
