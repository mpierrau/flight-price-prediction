
resource "aws_sagemaker_model" "sagemaker_model" {
  name = "${var.model_prefix}-model"
  execution_role_arn = var.execution_role_arn
  primary_container {
    image = var.model_image_url
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
  name = "${var.model_prefix}-endpoint-config"
  production_variants {
    variant_name = var.endpoint_variant_name
    model_name = aws_sagemaker_model.sagemaker_model.name
    initial_instance_count = 1
    instance_type = var.ec2_instance_type
    initial_variant_weight = 1.0
  }
}

# An endpoint config can't be replaced while it is being used by an endpoint
# So to make changes to the endpoint config we first switch to this identical
# "dummy" config endpoint, make changes in the real config and then switch back
# This is not a recommended way if one plans to update the endpoint a lot, but
# in our case we are planning on keeping it fixed so it's fine.
# TODO: Dynamically fetch variant values from "real" config
resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_config_dummy" {
  name = "${var.model_prefix}-endpoint-config-dummy"
  production_variants {
    variant_name = var.endpoint_variant_name
    model_name = aws_sagemaker_model.sagemaker_model.name
    initial_instance_count = 1
    instance_type = var.ec2_instance_type
    initial_variant_weight = 1.0
  }
}

resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name = "${var.model_prefix}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config.name

  depends_on = [ aws_sagemaker_endpoint_configuration.sagemaker_endpoint_config ]

  tags = {
    ModelIdentifier: "flight-price-predictor"
  }
}
