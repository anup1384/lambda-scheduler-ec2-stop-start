# Terraform variables file

variable "cloudwatch_schedule_expression" {
  description = "Define the aws cloudwatch event rule schedule expression"
  type        = string
  default     = "cron(0 22 ? * MON-FRI *)"
}

variable "name" {
  description = "Define name to use for lambda function, cloudwatch event and iam role"
  type        = string
}

variable "custom_iam_role_arn" {
  description = "Custom IAM role arn for the scheduling lambda"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "Default aws region"
  type        = string
  default     = "ap-south-1"
}

variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key."
  type        = string
  default     = null
}

variable "aws_regions" {
  description = "A list of one or more aws regions where the lambda will be apply, default use the current region"
  type        = list(string)
  default     = null
}

variable "schedule_action" {
  description = "Define schedule action to apply on resources, accepted value are 'stop or 'start"
  type        = string
  default     = "stop"
}

variable "resources_tag" {
  description = "Set the tag use for identify resources to stop or start"
  type        = map(string)

  default = {
    key   = "tostop"
    value = "true"
  }
}


variable "ec2_schedule" {
  description = "Enable scheduling on ec2 resources"
  type        = string
  default     = "false"
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the object."
  type        = map
}
