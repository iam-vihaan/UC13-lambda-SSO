resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  package_type  = var.image_uri != null ? "Image" : "Zip"
  image_uri     = var.image_uri
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = var.architectures

  dynamic "image_config" {
    for_each = var.image_uri != null ? [1] : []
    content {
      command           = try(var.image_config.command, null)
      entry_point       = try(var.image_config.entry_point, null)
      working_directory = try(var.image_config.working_directory, null)
    }
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids

    }
  }

  tags = var.tags
}
