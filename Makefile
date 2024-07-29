LOCAL_TAG:=$(shell date +"%Y-%m-%d-%H-%M")
LOCAL_IMAGE_NAME:=flight-price-prediction:${LOCAL_TAG}
SVC_API_PORT:=8080

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

launch_app:
	cd src/; \
	fastapi run wsgi.py --app app

predict:
	curl -X "POST" "http://localhost:8000/invocations" -d @integration-tests/data.json | jq

publish: build integration_test
	LOCAL_IMAGE_NAME=${LOCAL_IMAGE_NAME} bash scripts/publish.sh

setup:
	poetry lock --no-update
	poetry install --with dev
	pre-commit install
