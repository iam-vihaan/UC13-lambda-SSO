# Archive the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./modules/lambda/lambda_function.py"
  output_path = "./modules/lambda/lambda_function.zip"
}

# S3 bucket for frontend
resource "aws_s3_bucket" "kasi-hcl-bucket-uc13" {
  bucket = var.s3_bucket_name
}

# S3 bucket ACL (public-read)
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.kasi-hcl-bucket-uc13.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.kasi-hcl-bucket-uc13.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend_bucket_block]
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_block" {
  bucket                  = aws_s3_bucket.kasi-hcl-bucket-uc13.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# S3 website configuration
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.kasi-hcl-bucket-uc13.id

  index_document {
    suffix = "index.html"
  }
}

# Upload index.html to S3
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.kasi-hcl-bucket-uc13.id
  key          = "index.html"
  source       = "${path.module}/modules/frontend/index.html"
  content_type = "text/html"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "hello_world" {
  function_name    = "HelloWorldFunction"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hello_api.execution_arn}/*/*"
}


# API Gateway
resource "aws_api_gateway_rest_api" "hello_api" {
  name        = var.api_name
  description = var.description

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "hello_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello_method" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.hello_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hello_api.id
  resource_id             = aws_api_gateway_resource.hello_resource.id
  http_method             = aws_api_gateway_method.hello_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_world.invoke_arn
}

resource "aws_api_gateway_deployment" "hello_deploy" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
}

resource "aws_api_gateway_stage" "hello_stage" {
  deployment_id = aws_api_gateway_deployment.hello_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  stage_name    = "prod"
}


# Cognito SSO
resource "aws_cognito_user_pool" "user_pool" {
  name = "hello-world-user-pool"

  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  tags = var.tags
}

resource "aws_cognito_user" "kasi_user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = "kasiuser"
  temporary_password = "TempPass1234!"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "hello-world-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = ["https://your-frontend-url.com/callback"]
  logout_urls   = ["https://your-frontend-url.com/logout"]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "hello-world-app-domain"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_api_gateway_authorizer" "cognito_auth" {
  name                    = "CognitoAuthorizer"
  rest_api_id             = aws_api_gateway_rest_api.hello_api.id
  identity_source         = "method.request.header.Authorization"
  type                    = "COGNITO_USER_POOLS"
  provider_arns           = [aws_cognito_user_pool.user_pool.arn]
}

output "cognito_auth_info" {
  value = {
    user_pool_id   = aws_cognito_user_pool.user_pool.id
    client_id      = aws_cognito_user_pool_client.user_pool_client.id
    username       = aws_cognito_user.kasi_user.username
    temp_password  = aws_cognito_user.kasi_user.temporary_password
  }
  description = "Use these values to authenticate via AWS CLI or SDK and retrieve a token."
  sensitive   = true
}
