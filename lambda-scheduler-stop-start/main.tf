# Freeze aws provider version
terraform {
  required_version = ">= 0.12"

  required_providers {
    aws     = ">= 2.9.0"
    archive = ">= 1.2.2"
  }
}


provider "aws" {
  region  = var.aws_region
}

data "aws_region" "current" {}

################################################
#
#            IAM CONFIGURATION
#
################################################

resource "aws_iam_role" "this" {
  count       = var.custom_iam_role_arn == null ? 1 : 0
  name        = "${var.name}-scheduler-lambda"
  description = "Allows Lambda functions to stop and start ec2 and rds resources"
  tags = var.tags
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "schedule_ec2" {
  count = var.custom_iam_role_arn == null ? 1 : 0
  name  = "${var.name}-ec2-custom-policy-scheduler"
  role  = aws_iam_role.this[0].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:DescribeTags"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}



locals {
  lambda_logging_policy = {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  }
  lambda_logging_and_kms_policy = {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      },
      {
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:CreateGrant"
        ],
        "Resource": "${var.kms_key_arn}",
        "Effect": "Allow"
      }
    ]
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  count  = var.custom_iam_role_arn == null ? 1 : 0
  name   = "${var.name}-lambda-logging"
  role   = aws_iam_role.this[0].id
  policy = var.kms_key_arn == null ? jsonencode(local.lambda_logging_policy) : jsonencode(local.lambda_logging_and_kms_policy)
}

################################################
#
#            LAMBDA FUNCTION
#
################################################

# Convert *.py to .zip because AWS Lambda need .zip
data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/package/"
  output_path = "${path.module}/aws-stop-start-resources.zip"
}

# Create Lambda function for stop or start aws resources
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = var.name
  role             = var.custom_iam_role_arn == null ? aws_iam_role.this[0].arn : var.custom_iam_role_arn
  handler          = "scheduler.main.lambda_handler"
  source_code_hash = data.archive_file.this.output_base64sha256
  runtime          = "python3.7"
  timeout          = "600"
  tags             = var.tags
  kms_key_arn      = var.kms_key_arn == null ? "" : var.kms_key_arn

  environment {
    variables = {
      AWS_REGIONS               = var.aws_regions == null ? data.aws_region.current.name : join(", ", var.aws_regions)
      SCHEDULE_ACTION           = var.schedule_action
      TAG_KEY                   = var.resources_tag["key"]
      TAG_VALUE                 = var.resources_tag["value"]
      EC2_SCHEDULE              = var.ec2_schedule
    }
  }
}

################################################
#
#            CLOUDWATCH EVENT
#
################################################

resource "aws_cloudwatch_event_rule" "this" {
  name                = "trigger-lambda-scheduler-${var.name}"
  description         = "Trigger lambda scheduler"
  schedule_expression = var.cloudwatch_schedule_expression
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.name
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.this.function_name
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

################################################
#
#            CLOUDWATCH LOG
#
################################################
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
}
