# Project name should be same as project_id in tfvars
PROJECT_NAME:=flight-price-prediction
ENV ?= prod
DOCKER_IMAGE_NAME ?= prediction-app-${PROJECT_NAME}-${ENV}:latest
MLFLOW_APP_NAME ?= mlflow-tf
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query "Account" --output text)
PAR_NAME:=/${MLFLOW_APP_NAME}/${ENV}/MLFLOW_TRACKING_PASSWORD
MLFLOW_IMAGE_NAME ?= ${MLFLOW_APP_NAME}-${ENV}-image:latest

train_model_hyperpar_search register_model: export MLFLOW_EXPERIMENT_NAME ?= ${PROJECT_NAME}
train_model_hyperpar_search register_model: export MLFLOW_TRACKING_USERNAME ?= mlflow-user
train_model_hyperpar_search register_model: export MLFLOW_TRACKING_PASSWORD ?= $(shell aws ssm get-parameters \
		--names ${PAR_NAME} --with-decryption --query 'Parameters[0].Value' --output text)
train_model_hyperpar_search register_model: export MLFLOW_URI=http://$(shell aws elbv2 describe-load-balancers --query "LoadBalancers[0].DNSName" --output text)
register_model: export REF_DATA_BUCKET=data-${PROJECT_NAME}-${ENV}

TRAIN_DATA:=data/$(shell ls data/ | grep train_data -m1)
VAL_DATA:=data/$(shell ls data/ | grep validation_data -m1)

LAMBDA_IMAGE_NAME ?= monitoring-lambda-${PROJECT_NAME}-${ENV}

# Setting up poetry, pre-commit, prefect and terraform modules
setup:
	poetry lock --no-update
	poetry install --with dev
	pre-commit install
	prefect cloud login
	cd infrastructure/mlflow/;\
	terraform init;
	cd infrastructure/sagemaker/;\
	terraform init;
	cd infrastructure/monitoring/;\
	terraform init;

# Downloading data from kaggle
get_data:
	poetry run kaggle datasets download -d viveksharmar/flight-price-data -p data/; \
	unzip -o data/flight-price-data.zip -d data/

# Building rest of MLFlow server infra
build_mlflow_infra:
	cd infrastructure/mlflow/; \
	terraform apply -var-file="vars/${ENV}.tfvars"

# S3 Bucket for Data storage
# ECR for Monitoring container
build_data_infra:
	cd infrastructure/monitoring/; \
	terraform apply -target="aws_s3_bucket.data_bucket" -target="module.ecr.aws_ecr_repository.monitor_repo" -var-file="vars/${ENV}.tfvars"

# Preprocessing data
preprocess_data:
	poetry run python preprocessing/preprocess_data.py data/flight_dataset.csv

# Hyperparameter search for model
train_model_hyperpar_search:
	unset MLFLOW_RUN_ID;\
	poetry run python training/optimization.py ${TRAIN_DATA} $(VAL_DATA) --model-name XGBRegressor --num-trials 50 --loss-key rmse --target-column price --seed 19911991

# Register best model
# Also uploads training data to S3 bucket for data monitoring
register_model:
	unset MLFLOW_RUN_ID;\
	poetry run python training/register_model.py ${TRAIN_DATA} ${VAL_DATA} -n 3 -e ${MLFLOW_EXPERIMENT_NAME} -uri ${MLFLOW_URI} -t price -s 19911991

get_mlflow_info:
	@echo Adress: http://$(shell aws elbv2 describe-load-balancers --query "LoadBalancers[0].DNSName" --output text)
	@echo Username: mlflow-user
	@echo Password: $(shell aws ssm get-parameters --names /${MLFLOW_APP_NAME}/${ENV}/MLFLOW_TRACKING_PASSWORD --with-decryption --query 'Parameters[0].Value' --output text)

# Setup Sagemaker Endpoint infra
build_sagemaker_infra:
	cd infrastructure/sagemaker/; \
	terraform apply -var-file="vars/${ENV}.tfvars"

# Setup monitoring lambda
build_monitoring_infra:
	cd infrastructure/monitoring/; \
	terraform apply -var-file="vars/${ENV}.tfvars"

# Test endpoint
test_endpoint:
	poetry run python integration-tests/test_endpoint.py --region ${AWS_REGION} --endpoint-name "${PROJECT_NAME}-${ENV}-endpoint"

test:
	pytest tests/

quality_checks:
	isort .
	black .
	pylint --recursive=y .

integration_test: build
	DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME} bash integration-tests/run.sh

# Local tests
launch_local_app:
	cd app/src/ && \
	fastapi run wsgi.py --app app --port 8080

predict_local:
	curl -X "POST" "http://localhost:8080/invocations" -d @integration-tests/data.json
