#!/bin/bash
set -e

echo "Starting deployment..."

# Zip Lambda function
echo "Packaging Lambda function..."
cd terraform/lambda
zip -q lambda_function.zip lambda_function.py
cd ../..

# Apply Terraform infrastructure
echo "Applying Terraform infrastructure..."
cd terraform
terraform apply -auto-approve

# Get configuration from Terraform outputs
echo "Reading Terraform configuration..."
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
CLOUDFRONT_DIST_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "")
REGION="us-east-1"
cd ..

# Validate we got the values
if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_DIST_ID" ] || [ -z "$API_ENDPOINT" ]; then
  echo "Error: Could not read Terraform outputs"
  echo "Make sure you're in the portfolio directory and Terraform has been applied"
  exit 1
fi

echo "Bucket: $S3_BUCKET"
echo "Distribution: $CLOUDFRONT_DIST_ID"
echo "API: $API_ENDPOINT"

# Generate .env file for Astro
echo "Generating environment variables..."
cat > site/.env << EOF
PUBLIC_API_ENDPOINT=$API_ENDPOINT
EOF

# Build the site
echo "Building Astro site..."
cd site
npm run build

# Sync to S3
echo "Uploading to S3..."
aws s3 sync dist/ s3://$S3_BUCKET/ \
  --region $REGION \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html" \
  --exclude "*.xml"

# Upload HTML files with different cache settings
echo "Uploading HTML files..."
aws s3 sync dist/ s3://$S3_BUCKET/ \
  --region $REGION \
  --content-type "text/html" \
  --cache-control "public, max-age=0, must-revalidate" \
  --exclude "*" \
  --include "*.html"

# Invalidate CloudFront cache
echo "Invalidating CloudFront cache..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_DIST_ID \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text)

cd ..

echo "Deployment complete"
echo "CloudFront invalidation ID: $INVALIDATION_ID"
echo "Site will be live in 1-2 minutes"
echo "URL: https://$(aws cloudfront get-distribution --id $CLOUDFRONT_DIST_ID --query 'Distribution.DomainName' --output text)"