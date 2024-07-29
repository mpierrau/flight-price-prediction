resource "aws_sagemaker_model" "sagemaker_model" {
  name = "flight-price-prediction-model"
  execution_role_arn = aws_iam_role.sagemaker_role.arn
  primary_container {
    image = var.model_ecr_image
    mode = "SingleModel"
    environment = tomap(
      {
        MLFLOW_MODEL_URI = var.model_uri
      }
    )
    image_config {
      repository_access_mode = "Platform"
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_config" {
  name = "flight-price-endpoint-config"
  production_variants {
    variant_name = "variant-1"
    model_name = aws_sagemaker_model.sagemaker_model.name
    initial_instance_count = 1
    instance_type = var.ec2_instance_type
    initial_variant_weight = 1.0
  }
}

resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name = "flight-price-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config.name
}
