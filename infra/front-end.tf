resource "aws_s3_bucket" "front-end-s3-bucket" {
  bucket = "${var.s3_bucket_name}"

  tags = {
    Name = "${var.s3_bucket_name}"
  }


}

resource "aws_s3_bucket_public_access_block" "front-end-s3-bucket-public-access" {
  bucket = aws_s3_bucket.front-end-s3-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.front-end-s3-bucket.id
#   acl    = "private"
# }



########################################################################################################
#Removing this part of the code from here, since we intend to use terrafrom just to manage infrastructure
#Uploading content will be taken care by Github actions 
#########################################################################################################
# Fetch all files from the `files` directory
locals {
  source_directory = "${path.module}/../CherryBlossom" # Adjust the path as needed
  alternate_domain = "cherry-blossom1.neha-wadodkar.com"
  files            = fileset(local.source_directory, "**")
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "gif"  = "image/gif"
  }
}


########################################################################################################
#Removing this part of the code from here, since we intend to use terrafrom just to manage infrastructure
#Uploading content will be taken care by Github actions 
#########################################################################################################
# Upload each file to the S3 bucket
resource "aws_s3_object" "files" {
  for_each = tomap({ for file in local.files : file => file })

  bucket = aws_s3_bucket.front-end-s3-bucket.bucket
  key    = each.key                                  # Key in the S3 bucket
  source = "${local.source_directory}/${each.value}" # Local file path
  etag   = filemd5("${local.source_directory}/${each.value}")
  # Determine content_type based on file extension
  content_type = local.mime_types[tolist(split(".", each.value))[length(tolist(split(".", each.value))) - 1]]

  lifecycle {
    ignore_changes = [etag, source]
  }

}



# resource "aws_s3_bucket_policy" "public_read" {
#   bucket = aws_s3_bucket.front-end-s3-bucket.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "arn:aws:s3:::${aws_s3_bucket.front-end-s3-bucket.id}/*"
#       }
#     ]
#   })
# }



# Create the S3 bucket policy for public access to the index.html via CloudFront
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.front-end-s3-bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.front-end-s3-bucket.bucket}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.s3_distribution.arn}"
          }
        }
      }
    ]
  })
}

locals {
  s3_origin_id = "myS3Origin"
}

#Create an Origin Access Control for CloudFront to access S3
resource "aws_cloudfront_origin_access_control" "s3_access_control" {
  name                              = "s3-oac-${aws_s3_bucket.front-end-s3-bucket.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.front-end-s3-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_access_control.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AWS resume challange plus terraform"
  default_root_object = "index.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  aliases = ["${local.alternate_domain}"]



  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

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

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    #cloudfront_default_certificate = true
    acm_certificate_arn      = "arn:aws:acm:us-east-1:099345257938:certificate/60516fe8-adee-4ad1-8b22-ee00e2808da7"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}

resource "aws_route53_record" "alias_example" {
  zone_id = "Z041837825OSUSXM9UI76" # Hosted zone ID
  name    = local.alternate_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name # S3 or CloudFront domain
    zone_id                = "Z2FDTNDATAQYW2"                                        # Zone ID for S3 (or CloudFront)
    evaluate_target_health = false
  }
}


# resource "aws_s3_bucket" "example" {
#   bucket = "replaceable-data-bucket"
# }


# //lifecycle policy to delete old data
# resource "aws_s3_bucket_lifecycle_configuration" "delete_old" {
#   bucket = aws_s3_bucket.front-end-s3-bucket.id

#   rule {
#     id     = "delete-old-data"
#     status = "Enabled"

#     expiration {
#       days = 20
#     }
#   }
# }

