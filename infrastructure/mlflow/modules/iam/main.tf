data "aws_iam_policy" "bucket_access" {
  name = "AmazonS3FullAccess"
}

resource "aws_iam_user" "mlflow_s3" {
  name                 = "mlflow-access-s3"
  permissions_boundary = data.aws_iam_policy.bucket_access.arn
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.mlflow_s3.name
  policy_arn = data.aws_iam_policy.bucket_access.arn
}

resource "aws_iam_access_key" "mlflow_s3" {
  user = aws_iam_user.mlflow_s3.name

}

resource "aws_ssm_parameter" "mlflow_key_id" {
  name  = "/${var.app_name}/${var.env}/AWS_ACCESS_KEY_ID"
  type  = "SecureString"
  value = aws_iam_access_key.mlflow_s3.id
}

resource "aws_ssm_parameter" "mlflow_key_secret" {
  name  = "/${var.app_name}/${var.env}/AWS_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = aws_iam_access_key.mlflow_s3.secret
}

# MLFlow Server setup
data "aws_iam_policy" "cloud_watch" {
  name = "AWSOpsWorksCloudWatchLogs"
}

data "aws_iam_policy" "ecs_task_execution" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "access_ssm" {
  name        = "AccessSSM_MlFlow"
  path        = "/"
  description = "Policy for accessing SSM for MlFlow"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role" "ecs_mlflow" {
  name = "ECSMlFlow"

  managed_policy_arns = [
    aws_iam_policy.access_ssm.arn,
    data.aws_iam_policy.cloud_watch.arn,
    data.aws_iam_policy.ecs_task_execution.arn
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}
