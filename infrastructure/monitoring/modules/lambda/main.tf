resource "aws_lambda_function" "monitoring_lambda" {
  function_name = var.lambda_function_name
  # This can also be any base image to bootstrap the lambda config, unrelated to your Inference service on ECR
  # which would be anyway updated regularly via a CI/CD pipeline
  image_uri = var.image_uri # required-argument
  package_type = "Image"
  role = aws_iam_role.monitoring_lambda_role.arn
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      MLFLOW_RUN_ID=var.mlflow_run_id
      MLFLOW_MODEL_BUCKET=var.mlflow_model_bucket,
      MLFLOW_TRACKING_URI=var.mlflow_tracking_uri
      MLFLOW_ARTIFACT_PATH=var.mlflow_artifact_path
      MONITORING_DATA_BUCKET=var.monitoring_data_bucket
      MONITORING_TEST_DATA_FILE=null # We generate synthetic data
      MONITORING_REFERENCE_DATA_FILE=var.reference_data_path
      MONITORING_REPORT_BUCKET=var.report_bucket
    }
  }
  timeout = 180
  ephemeral_storage {
    size = 2048
  }
  memory_size = 512
}

locals {
  schedule = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.lambda_function_name}-cron-schedule"
  description         = "Cron trigger for lambda ${var.lambda_function_name}"
  schedule_expression = local.schedule
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "monitoring_lambda"
  arn       = aws_lambda_function.monitoring_lambda.arn
}

resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
}
