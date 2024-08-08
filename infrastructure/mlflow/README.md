## Infrastructure for an AWS hosted MLFlow tracking server
Setup by following [this blog post](https://dlabs.ai/blog/how-to-set-up-mlflow-on-aws/#item-15) by D-labs.

### Initialize ECR module
```sh
terraform init
terraform apply -target="module.ecr.aws_ecr_repository.mlflow_ecr" -var-file="vars/staging.tfvars"
```

### Authorize Docker to push to ECR
```sh
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### Build and push MLFlow docker image to ECR
```sh
IMAGE_NAME="mlflow-tf-stg-image"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest"
docker build src/ -t $ECR_URI
docker push $ECR_URI
```

### Build rest of infra
```sh
terraform apply -var-file="vars/staging.tfvars"
```
