output "api_endpoint" {
  description = "API Gateway endpoint for the AI application"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "s3_bucket_name" {
  description = "S3 bucket for storing AI data and models"
  value       = aws_s3_bucket.ai_data_bucket.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table for storing AI inference results"
  value       = aws_dynamodb_table.ai_results.name
}

output "sagemaker_model_name" {
  description = "SageMaker model name"
  value       = aws_sagemaker_model.ai_model.name
}
