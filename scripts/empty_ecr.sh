#!/bin/sh
# This script removes all existing images in the provided ECR repository

REPOSITORY_NAME=${1:-monitoring-lambda-flight-price-prediction-stg}

image_tags=$(aws ecr list-images --repository-name $REPOSITORY_NAME --query "imageIds[*].imageDigest" --output text)
if [ $image_tags=="" ]; then
    echo "No images to remove!"
    return 0
fi
arg=''
for tag in $image_tags; do
    arg="$arg imageDigest=$tag"
done
aws ecr batch-delete-image --repository-name $REPOSITORY_NAME --image-ids $arg
