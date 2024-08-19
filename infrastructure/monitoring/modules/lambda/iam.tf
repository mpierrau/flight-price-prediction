resource "aws_iam_role" "monitoring_lambda_role" {
  name = "role_${var.lambda_function_name}"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com",
                    "s3.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# IAM for CW

resource "aws_iam_policy" "allow_logging" {
    name = "allow_logging_${var.lambda_function_name}"
    path = "/"
    description = "IAM policy for logging from a lambda"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.monitoring_lambda_role.name
  policy_arn = aws_iam_policy.allow_logging.arn
}

# IAM for S3

resource "aws_iam_policy" "lambda_s3_role_policy" {
  name = "lambda_s3_policy_${var.lambda_function_name}"
  description = "IAM Policy for S3"
  # TODO: change policies below to reflect get operation
policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.report_bucket}",
                "arn:aws:s3:::${var.report_bucket}/*",
                "arn:aws:s3:::${var.monitoring_data_bucket}",
                "arn:aws:s3:::${var.monitoring_data_bucket}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:Describe*",
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam-policy-attach" {
  role = aws_iam_role.monitoring_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_role_policy.arn
}
