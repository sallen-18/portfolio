resource "aws_cloudfront_origin_access_control" "portfolio_oac" {
  name                              = "portfolio_oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_function" "url_rewrite" {
  name    = "url-rewrite-terraform"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite URLs to append /index.html for clean URLs"
  publish = true
  
  code = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Check if URI is missing a file extension and doesn't end with /
    if (!uri.includes('.') && !uri.endsWith('/')) {
        request.uri = uri + '/index.html';
    }
    // If it ends with /, append index.html
    else if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
    }
    
    return request;
}
  EOT
}


resource "aws_cloudfront_distribution" "portfolio_distribution" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"  # North America + Europe (cheapest)

  # Origin - Your S3 bucket
  origin {
    domain_name              = aws_s3_bucket.portfolio_site.bucket_regional_domain_name
    origin_id                = "S3-portfolio"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio_oac.id
  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id       = "S3-portfolio"  # Must match origin_id above
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # Attach your URL rewrite function
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use CloudFront's default SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_s3_bucket_policy" "portfolio_site" {
  bucket = aws_s3_bucket.portfolio_site.id

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio_site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.portfolio_distribution.arn
          }
        }
      }
    ]
  })
}