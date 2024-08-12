
resource "aws_sagemaker_model" "sagemaker_model" {
  name = "${var.model_suffix}-model"
  execution_role_arn = var.execution_role_arn #aws_iam_role.sagemaker_role.arn
  primary_container {
    image = var.model_image_url #"${aws_ecr_repository.model_repo.name}:${var.ecr_image_tag}"
    mode = "SingleModel"
    environment = {
        MLFLOW_MODEL_URI = var.mlflow_model_uri
    }
    image_config {
      repository_access_mode = "Platform"
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_config" {
  name = "${var.model_suffix}-endpoint-config"
  production_variants {
    variant_name = var.endpoint_variant_name
    model_name = aws_sagemaker_model.sagemaker_model.name
    initial_instance_count = 1
    instance_type = var.ec2_instance_type
    initial_variant_weight = 1.0
  }
}

resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name = "${var.model_suffix}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config.name
}
