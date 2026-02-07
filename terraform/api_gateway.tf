# REST API
resource "aws_api_gateway_rest_api" "visitor_api" {
  name        = "visitor-counter-api-terraform"
  description = "API for visitor counter - managed by Terraform"
}

# GET method on root resource
resource "aws_api_gateway_method" "get_visitor_count" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_rest_api.visitor_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_api.id
  resource_id             = aws_api_gateway_rest_api.visitor_api.root_resource_id
  http_method             = aws_api_gateway_method.get_visitor_count.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_counter.invoke_arn
}

# Lambda permission
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "visitor_api" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

# Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.visitor_api.id
  rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
  stage_name    = "prod"
}