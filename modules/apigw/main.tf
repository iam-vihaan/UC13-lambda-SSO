# CloudWatch Logs Role for API Gateway (account-wide setting)
resource "aws_iam_role" "api_gateway_cloudwatch" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name = "${var.api_name}-api-gw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  role       = aws_iam_role.api_gateway_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch[0].arn
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

# Resource for your specific path
resource "aws_api_gateway_resource" "my_resource" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "orders"
}

# GET method for the resource
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.my_resource.id
  http_method   = "GET"
  authorization = var.authorization_type
  authorizer_id = var.authorizer_id
}

# Lambda integration for the GET method
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.my_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_function_arn != null ? "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations" : null
}

# Deployment
resource "aws_api_gateway_deployment" "this" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.body,
      aws_api_gateway_integration.lambda_integration.uri,
      aws_api_gateway_method.get_method
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "this" {
  depends_on = [aws_api_gateway_account.this]

  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  description   = var.stage_description

  # Access logging (optional)
  dynamic "access_log_settings" {
    for_each = var.access_log_destination_arn != null ? [1] : []
    content {
      destination_arn = var.access_log_destination_arn
      format          = var.access_log_format
    }
  }

  tags = var.tags
}





# Method settings
resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "${aws_api_gateway_resource.my_resource.path_part}/${aws_api_gateway_method.get_method.http_method}"

  settings {
    metrics_enabled        = var.metrics_enabled
    logging_level          = var.enable_cloudwatch_logging ? var.logging_level : "OFF"
    data_trace_enabled     = var.enable_cloudwatch_logging ? var.data_trace_enabled : false
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}
