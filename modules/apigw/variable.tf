# API Gateway Configuration
variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "description" {
  description = "Description of the API"
  type        = string
  default     = ""
}

variable "endpoint_type" {
  description = "API Gateway endpoint type (REGIONAL, EDGE, or PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

# Lambda Integration
variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

# Stage Configuration
variable "stage_name" {
  description = "Name of the deployment stage"
  type        = string
  default     = "prod"
}

variable "stage_description" {
  description = "Description of the deployment stage"
  type        = string
  default     = "Production environment"
}

# Authorization
variable "authorization_type" {
  description = "Type of authorization (NONE, AWS_IAM, CUSTOM, COGNITO_USER_POOLS)"
  type        = string
  default     = "NONE"
}

variable "authorizer_id" {
  description = "ID of the authorizer"
  type        = string
  default     = null
}

variable "logging_level" {
  description = "Logging level (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "data_trace_enabled" {
  description = "Whether to enable data tracing"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the API Gateway resources"
  type        = map(string)
  default     = {}
}


variable "throttling_burst_limit" {
  description = "API throttling burst limit"
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "API throttling rate limit"
  type        = number
  default     = 50
}



variable "aws_region" {
  description = "AWS region for the API Gateway"
  type        = string

}
