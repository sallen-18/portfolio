output "api_endpoint" {
  value       = aws_api_gateway_stage.prod.invoke_url
  description = "API Gateway endpoint URL"
}

output "cloudfront_url" {
  value       = aws_cloudfront_distribution.portfolio_distribution.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.portfolio_distribution.id
  description = "CloudFront distribution ID"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.portfolio_site.bucket
  description = "S3 bucket name"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.visitors_table.name
  description = "DynamoDB table name"
}

output "lambda_function_name" {
  value       = aws_lambda_function.visitor_counter.function_name
  description = "Lambda function name"
}