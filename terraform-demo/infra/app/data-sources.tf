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

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}