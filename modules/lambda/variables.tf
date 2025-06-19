variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "image_uri" {
  type        = string
  default     = null
  description = "ECR image URI (required for package_type=Image)"
}

variable "role_arn" {
  type        = string
  description = "ARN of the IAM execution role"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Memory allocation in MB (64-10240)"
}

variable "timeout" {
  type        = number
  default     = 3
  description = "Timeout in seconds (max 900)"
}

variable "architectures" {
  type        = list(string)
  default     = ["x86_64"] # or ["arm64"]
  description = "CPU architecture"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Environment variables"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "VPC subnet IDs (required for VPC)"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "VPC security group IDs"
}


variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}



variable "image_config" {
  type = object({
    command           = optional(list(string), null)
    entry_point       = optional(list(string), null)
    working_directory = optional(string, null)
  })
  default     = {}
  description = "Configuration for Lambda image (command, entry point, working directory)"

}
