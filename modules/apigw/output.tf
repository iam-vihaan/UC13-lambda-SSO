
# API Gateway Outputs
output "rest_api_id" {
  description = "The ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_root_resource_id" {
  description = "The root resource ID of the REST API"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

output "rest_api_endpoint" {
  description = "The base endpoint URL of the REST API"
  value       = aws_api_gateway_stage.this.invoke_url
}

# Stage Outputs
output "stage_name" {
  description = "The name of the deployed stage"
  value       = aws_api_gateway_stage.this.stage_name
}

# Resource Outputs
output "resource_id" {
  description = "The ID of the API resource (for your GET method)"
  value       = aws_api_gateway_resource.my_resource.id
}

# Method Outputs
output "get_method_http_method" {
  description = "The HTTP method of your GET endpoint"
  value       = aws_api_gateway_method.get_method.http_method
}

# Full Invoke URL for your specific endpoint
output "get_endpoint_url" {
  description = "The full invoke URL for your GET endpoint"
  value       = "${aws_api_gateway_stage.this.invoke_url}/${aws_api_gateway_resource.my_resource.path_part}"
}

# CloudWatch Logs
output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Logs group (if access logging is enabled)"
  value       = try(aws_api_gateway_stage.this.access_log_settings[0].destination_arn, null)
}



output "execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "invoke_url" {
  description = "Base URL for API Gateway stage"
  value       = aws_api_gateway_stage.this.invoke_url
}
