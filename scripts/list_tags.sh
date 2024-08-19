#!/bin/bash

# Define the specific tag key you're looking for
TARGET_TAG_KEY=${1:-ModelIdentifier}
TARGET_TAG_VALUE=${2:-flight-price-predictor}

# List all SageMaker endpoint names and arns
ENDPOINT_NAMES=($(aws sagemaker list-endpoints --query "Endpoints[*].EndpointName" --output text))
ENDPOINT_ARNS=($(aws sagemaker list-endpoints --query "Endpoints[*].EndpointArn" --output text))

# Iterate over each endpoint ARN and name
for i in $(seq 0 $((${#ENDPOINT_NAMES[@]}-1))); do
    # Get the tags for the endpoint
    TAGS=$(aws sagemaker list-tags --resource-arn ${ENDPOINT_ARNS[$i]} --query "Tags" --output json)

    # Check if the target tag is present, if so stop and echo endpoint name
    if echo "$TAGS" | jq -e ".[] | select(.Key == \"$TARGET_TAG_KEY\" and .Value == \"$TARGET_TAG_VALUE\")" > /dev/null; then
        echo "${ENDPOINT_NAMES[$i]}"
        exit 0
    fi
done

exit 1
