# These are only here for naming and may be changed
# but then also require changes in infrastructure/sagemaker/vars.
env = "prod"
aws_region = "eu-north-1"
project_id = "flight-price-prediction"

# Do not change these unless you know what you are doing
ecr_repo_name = "monitoring-lambda"
lambda_function_name = "monitoring_lambda"
report_bucket_name = "data-report"
reference_data_bucket_name = "data"
ecr_image_tag = "latest"
src_dir = "src/"
mlflow_model_bucket = "artifact-bucket-mlflow-tf-prod"

# Update me!
mlflow_run_id = "2/40955e4338c14174aa6311cd9c5252fe"
