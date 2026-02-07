# Zip the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/lambda_function.py"
  output_path = "lambda/lambda_function.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "visitor_counter_role" {
  name = "visitor_counter_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
# DynamoDB permissions
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_access"
  role = aws_iam_role.visitor_counter_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = aws_dynamodb_table.visitors_table.arn
    }]
  })
}

# CloudWatch Logs permission
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.visitor_counter_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "visitorCounter-terraform"
  role             = aws_iam_role.visitor_counter_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.14"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.visitors_table.name
      ALLOWED_ORIGIN = "https://${aws_cloudfront_distribution.portfolio_distribution.domain_name}"
    }
  }
}