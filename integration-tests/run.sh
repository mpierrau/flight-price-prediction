#!/usr/bin/env bash

# When first non-zero code returned, exit entire script with non-zero code
#set -e

if [[ -z "${GITHUB_ACTIONS}" ]]; then
    cd "$(dirname "$0")"
fi

if [ "${LOCAL_IMAGE_NAME}" == "" ]; then
    LOCAL_TAG=`date +x"%Y-%m-%d-%H-%M"`
    export LOCAL_IMAGE_NAME="flight-price-prediction:${LOCAL_TAG}"
    echo "LOCAL_IMAGE_NAME is not set, building a new image with tag ${LOCAL_TAG}"
    docker build -t ${LOCAL_IMAGE_NAME} ..
else
    echo "no need to build image ${LOCAL_IMAGE_NAME}"
fi

export SVC_API_PORT=8080
export MLFLOW_MODEL_URI="s3://mlflow-models-magnus-dev/5/02ab125dbc784fd19d21159287170fa0/artifacts/model/"

container_id=$(docker run --rm -d -p ${SVC_API_PORT}:${SVC_API_PORT} -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} ${LOCAL_IMAGE_NAME})

sleep 1

poetry run python test_docker.py

ERROR_CODE=$?

if [ ${ERROR_CODE} != 0 ]; then
    docker logs ${LOCAL_IMAGE_NAME}
    docker kill ${LOCAL_IMAGE_NAME}
    exit ${ERROR_CODE}
fi

echo 'test_docker OK'
docker kill ${container_id} >/dev/null
