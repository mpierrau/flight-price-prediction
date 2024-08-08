# flight-price-prediction
My Final Project for the DataTalks MLOPS Zoomcamp 2024.
Prerequisites:
- AWS Account
- Prefect Cloud Account (create one for free [here]((https://docs.prefect.io/2.14.2/getting-started/quickstart/#step-2-connect-to-prefects-api)))
Developed on Ubuntu 23.10.

## Setup

### Dependency installation
1. Install [`poetry`](https://python-poetry.org/docs/)
2. Install the [`aws cli v2`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. Navigate to the root folder (`flight-price-prediction/`) and install dependencies:
```sh
make setup
```
4. Go to `flight-price-prediction/infrastructure/mlflow/main.tf` and `flight-price-prediction/infrastructure/sagemaker/main.tf` and change `mpierrau` to some other unique identifier (the S3 bucket name needs to be unique across all of the internet).
```terraform
terraform {
  ...
  backend "s3" {
    bucket = "mpierrau-tf-state-flight-price-prediction"
    ...
  }
}
```

### Download data from Kaggle
```bash
make get_data
```

### Build AWS hosted `MLFlow` server
1. Authenticate against AWS using `aws configure sso` and then `aws sso login`.
    - [Medium blog post](https://medium.com/@mrethers/boss-way-to-authenticate-aws-cli-with-sso-for-multi-account-orgs-aa8a5e228bdd)
    - [ChatGPT help](https://chatgpt.com/share/95c6bc77-0acf-4468-bcae-99e515c9e92a)
1. [Install terraform.](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
2. Run the make command below. It will:
    1. Create an ECR repo
    2. Build and upload the Docker container for the MLFlow server app to the ECR repo
    3. Build the rest of the required infra for the server (IAM roles, ECS service and task, network settings, RDS postgres DB, S3 bucket)
```bash
make build_mlflow_infra
```

## Preprocessing
Performs feature engineering and creates train/test split of the data.
```sh
make preprocess_data
```

## Training
First we do some hyperparameter tuning on the data. Default is 50 runs, which takes a couple of minutes.
```sh
make train_model_hyperpar_search
```
Then we register the best model.
```sh
make register_model
```

## Test inference locally
After training you can test the model:
```bash
make launch_local_app
make predict_local
```

## To see the MLFlow UI
1. Find the DNS of the server:
```bash
aws elbv2 describe-load-balancers --query "LoadBalancers[0].DNSName"
```

2. Go to the DNS retrieved in 1 in a browser.

3. You will need credentials. These were automatically generated and are stored in AWS SSM. The username is `mlflow-user`. Retrieve the password using:
```bash
ENV=prod
APP_NAME=mlflow-tf
aws ssm get-parameters --names /${MLFLOW_TF}/${ENV}/MLFLOW_TRACKING_PASSWORD --with-decryption --query 'Parameters[0].Value'
```

4. Enter the credentials in the popup and you should be in!
