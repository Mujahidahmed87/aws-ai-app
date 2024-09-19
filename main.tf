provider "aws" {
  region = var.aws_region
}

# S3 Bucket for storing data and models
resource "aws_s3_bucket" "ai_data_bucket" {
  bucket = "${var.app_name}-data-bucket"
  acl    = "private"
}

# SageMaker for Model Training and Inference
resource "aws_sagemaker_model" "ai_model" {
  name                  = "${var.app_name}-model"
  execution_role_arn    = aws_iam_role.sagemaker_role.arn
  primary_container {
    image               = var.sagemaker_image_uri  # Pre-built SageMaker container image for inference
    model_data_url      = aws_s3_bucket.ai_data_bucket.bucket
  }
}

# Lambda function to invoke SageMaker
resource "aws_lambda_function" "invoke_sagemaker" {
  filename         = "lambda_function_payload.zip"
  function_name    = "${var.app_name}_invoke_sagemaker"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  
  # Lambda environment variables (if necessary)
  environment {
    variables = {
      SAGEMAKER_MODEL_NAME = aws_sagemaker_model.ai_model.name
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.app_name}_lambda_exec_role"
  
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach Policy to Lambda to interact with SageMaker and S3
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# API Gateway to trigger the Lambda function
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.app_name}-api"
  description = "API for invoking AI model"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "invoke"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.invoke_sagemaker.invoke_arn
}

# DynamoDB (or RDS) for storing application state or AI inference results
resource "aws_dynamodb_table" "ai_results" {
  name           = "${var.app_name}_results"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "result_id"

  attribute {
    name = "result_id"
    type = "S"
  }
}

# SageMaker IAM Role
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.app_name}_sagemaker_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "sagemaker.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach Policy to SageMaker Role for access to S3
resource "aws_iam_role_policy_attachment" "sagemaker_s3_policy" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
