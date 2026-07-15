# A data source is a read-only block that queries information from AWS or other external sources.
# Unlike Terraform resources, which have a full lifecycle of create, update, and delete, data sources only retrieve data at runtime to make configurations dynamic

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "origin_policy_website_bucket" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.justreadit_website_assets_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website_assets_s3_distribution.arn]
    }
  }
}

data "aws_iam_policy_document" "origin_policy_user_content_bucket" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    # Only allows the CloudFront distribution access to /covers and /banners folder inside the bucket
    # That way, the folder /ebooks and its contents will never be served through CloudFront, only via the S3 presigned URLs
    resources = [
      "${aws_s3_bucket.justreadit_user_content_bucket.arn}/covers",
      "${aws_s3_bucket.justreadit_user_content_bucket.arn}/banners*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.user_content_s3_distribution.arn]
    }
  }
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}