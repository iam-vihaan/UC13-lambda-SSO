variable "aws_region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for frontend hosting"
  type        = string
  default     = "kasi-hcl-bucket-uc13"
}

variable "api_name" {
  description = "The name of the API Gateway"
  type        = string
  default     = "HelloWorldAPI"
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "API for Hello World Lambda"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
