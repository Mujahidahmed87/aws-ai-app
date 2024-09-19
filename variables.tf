variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "AI Application Name"
  type        = string
}

variable "sagemaker_image_uri" {
  description = "SageMaker Pre-built Container for Model"
  type        = string
  default     = "763104351884.dkr.ecr.us-east-1.amazonaws.com/tensorflow-inference:2.3.0-cpu"  # Example TensorFlow image
}
