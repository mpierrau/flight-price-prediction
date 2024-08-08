LOCAL_TAG := $(shell date +"%Y-%m-%d-%H-%M")
LOCAL_IMAGE_NAME ?= flight-price-prediction:${LOCAL_TAG}
SVC_API_PORT := 8080
ENV ?= prod
MLFLOW_APP_NAME ?= mlflow-tf
PAR_NAME:=/${MLFLOW_APP_NAME}/${ENV}/MLFLOW_TRACKING_PASSWORD
MLFLOW_IMAGE_NAME ?= mlflow-tf-prod-image:latest
train_model_hyperpar_search register_model: export MLFLOW_EXPERIMENT_NAME ?= flight-price-prediction
train_model_hyperpar_search register_model: export MLFLOW_TRACKING_USERNAME ?= mlflow-user
train_model_hyperpar_search register_model: export MLFLOW_TRACKING_PASSWORD ?= $(shell aws ssm get-parameters \
		--names ${PAR_NAME} --with-decryption --query 'Parameters[0].Value' --output text)
train_model_hyperpar_search register_model: export MLFLOW_URI=http://$(shell aws elbv2 describe-load-balancers --query "LoadBalancers[0].DNSName" --output text)

TRAIN_DATA:=data/$(shell ls data/ | grep train_data -m1)
VAL_DATA:=data/$(shell ls data/ | grep validation_data -m1)

setup:
	poetry lock --no-update
	poetry install --with dev
	pre-commit install
	prefect cloud login

get_data:
	poetry run kaggle datasets download -d viveksharmar/flight-price-data -p data/; \
	unzip -o data/flight-price-data.zip

build_mlflow_ecr:
	cd infrastructure/mlflow/; \
	terraform init; \
	terraform apply -target="module.ecr.aws_ecr_repository.mlflow_ecr" -var-file="vars/${ENV}.tfvars"

build_push_mlflow_container: build_mlflow_ecr
	aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com; \
	docker build -t ${MLFLOW_IMAGE_NAME} infrastructure/mlflow/src/; \
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${MLFLOW_IMAGE_NAME}

build_mlflow_infra: build_push_mlflow_container
	cd infrastructure/mlflow/; \
	terraform init; \
	terraform apply -var-file="vars/${ENV}.tfvars"

preproc_data:
	poetry run python preprocessing/preprocess_data.py data/flight_dataset.csv

train_model_hyperpar_search:
	poetry run python training/optimization.py ${TRAIN_DATA} $(VAL_DATA) --model-name XGBRegressor --num-trials 50 --loss-key rmse --target-column price --seed 19911991

register_model:
	poetry run python training/register_model.py ${TRAIN_DATA} ${VAL_DATA} -n 5 -e ${MLFLOW_EXPERIMENT_NAME} -uri ${MLFLOW_URI} -t price -s 19911991

build_sagemaker_infra:
	cd infrastructure/sagemaker/; \
	terraform init; \
	terraform apply -target="module.ecr.aws_ecr_repository.mlflow_ecr" -var-file="vars/${ENV}.tfvars"

test:
	pytest tests/

quality_checks:
	isort .
	black .
	pylint --recursive=y .

build: quality_checks test
	docker build -t ${LOCAL_IMAGE_NAME} .

integration_test: build
	LOCAL_IMAGE_NAME=${LOCAL_IMAGE_NAME} bash integration-tests/run.sh

launch_local_app:
	cd src/ && \
	fastapi run wsgi.py --app app

predict_local:
	curl -X "POST" "http://localhost:8000/invocations" -d @integration-tests/data.json
