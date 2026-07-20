resource "aws_db_instance" "justreadit_postgres_db" {
  allocated_storage           = 20
  max_allocated_storage       = 100 # Enables autoscaling because > allocated_storage 
  db_name                     = "justreadit_db"
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = "db.t4g.micro"
  storage_type                = "gp2"
  identifier                  = "${local.name}-instance-demo"
  username                    = "postgres_admin"
  manage_master_user_password = true # Automatically creates an entry in Secrets Manager
  skip_final_snapshot         = true # For demo app only
  db_subnet_group_name        = aws_db_subnet_group.postgres_subnet_group.name
  publicly_accessible         = false
  storage_encrypted           = true
  deletion_protection         = false
  backup_retention_period     = 7 # Enables automated backups

  vpc_security_group_ids = [
    aws_security_group.sg_rds.id
  ]
}

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name = "${local.name}-postgres-subnet-group"

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = local.tags
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "justreadit_website_assets_bucket" {
  bucket        = "${local.name}-app-website-assets"
  force_destroy = true # Destroys all objects upon bucket destruction

  # No CORS policy needed as all the content is served through CloudFront as a single origin

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "justreadit_website_bucket_block_public" {
  bucket = aws_s3_bucket.justreadit_website_assets_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.justreadit_website_assets_bucket.bucket
  policy = data.aws_iam_policy_document.origin_policy_website_bucket.json
}

resource "aws_cloudfront_origin_access_control" "justreadit_cloudfront_oac" {
  name                              = "${local.name}-oac"
  description                       = "Allows CloudFront to retrieve content from configured private S3 buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website_assets_s3_distribution" {
  # Website assets origin
  origin {
    domain_name              = aws_s3_bucket.justreadit_website_assets_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.justreadit_cloudfront_oac.id
    origin_id                = "website-s3-origin"
  }

  # API backend origin
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "api-alb-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # To change to HTTPS once ALB is configured with TLS certificate
      origin_ssl_protocols   = ["TLSv1.2"] # Meaningless until TLS certificate is up
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Default caching behaviour is using the AWS-managed "CachingOptimized" policy
  default_cache_behavior {
    target_origin_id       = "website-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress        = true
  }

  # Cache rank 0, highest precedence
  ordered_cache_behavior {
    target_origin_id       = "api-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "/api/*"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
    compress        = true
  }

  # Using CloudFront default TLS certificate to redirect to HTTPS
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket" "justreadit_user_content_bucket" {
  bucket        = "${local.name}-app-user-content-${random_id.bucket_suffix.hex}"
  force_destroy = true # Destroys all objects upon bucket destruction

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "justreadit_user_content_bucket_block_public" {
  bucket = aws_s3_bucket.justreadit_user_content_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "demo_ebook" {
  bucket       = aws_s3_bucket.justreadit_user_content_bucket.id
  key          = "ebooks/demo-book.txt"
  source       = "${path.module}/assets/dummy-ebook.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/assets/dummy-ebook.txt")

  tags = local.tags
}

resource "aws_s3_bucket_policy" "user_content_bucket_policy" {
  bucket = aws_s3_bucket.justreadit_user_content_bucket.bucket
  policy = data.aws_iam_policy_document.origin_policy_user_content_bucket.json
}

resource "aws_cloudfront_distribution" "user_content_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.justreadit_user_content_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.justreadit_cloudfront_oac.id
    origin_id                = "user-content-s3-origin"
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Default caching behaviour is using the AWS-managed "CachingDisabled" policy.
  # Technically not needed as the S3 bucket policy only allows access to /banners/* and /covers/* (/ebooks/* is excluded because accessed through presigned URLs), 
  # but having 2 explicitly configured ordered cache behaviours and a default "no cache" is making the intent clear
  default_cache_behavior {
    target_origin_id       = "user-content-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
    compress        = true
  }

  # Cache rank 0, highest precedence
  ordered_cache_behavior {
    target_origin_id       = "user-content-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "/covers/*"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress        = true
  }

  # Cache rank 1, second highest precedence
  ordered_cache_behavior {
    target_origin_id       = "user-content-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "/banners/*"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress        = true
  }

  # Using CloudFront default TLS certificate to redirect to HTTPS
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = local.tags
}
