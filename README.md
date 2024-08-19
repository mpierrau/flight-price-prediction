# Flight Price Prediction
This is my final project for the DataTalks MLOPS Zoomcamp 2024.

The project builds infrastructure for serving an XGBoost model for predicting the price of flight tickets on a number of Indian airlines. The problem itself is a toy example and was chosen to keep the problem simple and focus on the surrounding infrastructure.

The infrastructure is divided into three parts, one for the MLFlow tracking server, one for data monitoring and one for hosting the model as a Sagemaker Endpoint.

Please note that this project does create resources on AWS which may incur some minor cost for the user. The maximum cost for a single day during development has been $13. If you do create the resources, please remember to [destroy them](##teardown) after you are finished testing.

## Prerequisites:
- An AWS Account
- Prefect Cloud Account (create one for free [here]((https://docs.prefect.io/2.14.2/getting-started/quickstart/#step-2-connect-to-prefects-api)))

The project was developed and tested on Ubuntu 23.10 and 24.04.

The preprocessing and training is monitored/logged using `prefect`. All runs can be reviewed using the Prefect Cloud UI.

All infrastructure is managed by Terraform. If anything fails during the `apply` stage the issue may resolve itself by running `terraform apply` (or the `make` command) one more time. If the error persists then something else is the issue.

There are 4 variables which will need to be changed from the current settings. I have highlighted these with **bold** in the readme below, please read it carefully! The pars are with regards to:
- [Terraform state bucket name](#update-terraform-state-bucket)
- [`model_id` in Model Registering](#register-model)
- [`alarm_subscribers` in Serving](#serving)
- [`mlflow_run_id` in Monitoring](#monitoring)

## Setup

### Dependencies
In order to build this repository the following tools are required, in addition to those specified in `pyproject.toml` and [Prerequisites](#prerequisites).
Follow the links for install instructions.
Even if you have slightly different versions installed, the code will probably still work, but the versions listed below were those used for developing and building the project locally and I recommend using the same versions:
- [`python 3.11.9`](https://www.python.org/downloads/release/python-3119/)
- [`poetry 1.8.2`](https://python-poetry.org/docs/)
- [`aws-cli 2.15.15`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [`docker 27.1.2`](https://docs.docker.com/engine/install/)
- [`terraform 1.9.4`](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Update terraform state bucket
**Go to the following files and change** `mpierrau` to some other unique identifier (the S3 bucket name needs to be unique across all of the internet):
  - [`infrastructure/mlflow/main.tf`](infrastructure/mlflow/main.tf#L9)
  - [`infrastructure/sagemaker/main.tf`](infrastructure/sagemaker/main.tf#L9)
  - [`infrastructure/monitoring/main.tf`](infrastructure/monitoring/main.tf#L11)
```terraform
terraform {
  ...
  backend "s3" {
    bucket = "tf-state-flight-price-prediction-mpierrau"
    ...
  }
}
```

### Install project dependencies
Navigate to the root folder (`flight-price-prediction/`) and install project package dependencies:
```sh
make setup
```

### Download data from Kaggle
```sh
make get_data
```

### Build AWS hosted `MLFlow` server
1. Authenticate against AWS using `aws configure sso` and then `aws sso login`. Help resources:
    - [Medium blog post](https://medium.com/@mrethers/boss-way-to-authenticate-aws-cli-with-sso-for-multi-account-orgs-aa8a5e228bdd)
    - [ChatGPT help](https://chatgpt.com/share/95c6bc77-0acf-4468-bcae-99e515c9e92a)
2. Run the make command below. It will:
    1. Create an ECR repo
    2. Build and upload the Docker container for the MLFlow server app to the ECR repo
    3. Build the rest of the required infra for the server (IAM roles, ECS service and task, network settings, RDS postgres DB, S3 bucket)
```sh
make build_mlflow_infra
```
This can take up to 15-20 minutes.

We also need some infra for training, tracking and monitoring (and S3 bucket and ECR repo):
```sh
make build_data_infra
```

## Preprocessing
Performs preprocessing of data and creates train/test split of the data. The features are created on-the-fly in the `sklearn` pipeline, so there is no need to create a dataset in advance with all features.
```sh
make preprocess_data
```

## Training
### Hyperparameter tuning
First we do some local hyperparameter tuning on the data. Default is 30 runs, which takes a couple of minutes, depending on your machine. With the given seeds we get a model with a lowest loss of ~2900 rupees. We only log the metadata of these models - no artifacts.
```sh
make train_model_hyperpar_search
```

### Register model
Then we locally train and register the 3 best models. The models that are saved are actually pipelines which performs feature engineering and feature selection before the inference step. These all get their artifacts uploaded to S3 via MLFlow. We also upload training script and feature engineering for tracability.
```sh
make register_model
```

Once the models are registered, the model id of the model with the lowest loss will be printed in the terminal. Take the Experiment ID and Run ID and **replace the current value** of `model_id` in [`stg.tfvars`](infrastructure/sagemaker/vars/stg.tfvars#L16) (and [`prod`](infrastructure/sagemaker/vars/prod.tfvars#L16)) with the new values as `'{experiment_id}/{run_id}'`.

If you want to head to the MLFlow UI to find another model ID follow the instructions below.

### To open the AWS MLFlow UI
Run:
```sh
make get_mlflow_info
```
Go to the returned DNS adress in a browser and enter the username and password (these were automatically generated during the build process and are stored in AWS SSM).

## Serving
Serve the model via an Sagemaker Endpoint and build related Cloudwatch alarms and a Subscribable SNS topic. If you wish to add your email to the subscription, **append your email** to the list `alarm_subscribers` in [`stg.tfvars`](infrastructure/sagemaker/vars/stg.tfvars#L17) (and [`prod`](infrastructure/sagemaker/vars/prod.tfvars#L17)). Then run:
```sh
make build_sagemaker_infra
```
You will receive a confirmation email in which you need to confirm the subscription. Please note that Terraform does not have the capability to keep track of which subscriptions are confirmed or not, which may cause issues when destroying this resource if the subscription has not been confirmed. See the [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) for more information.

This can take up to 10 minutes.

## Monitoring
Builds an AWS Lambda function which creates an EvidentlyAI report once daily and uploads it to an S3 bucket.
The link to the S3 bucket is outputted as `report_bucket` once this command has successfully completed.

Here, again you are required to **update** `mlflow_run_id` in [`infrastructure/monitoring/vars/stg.tfvars`](infrastructure/monitoring/vars/stg.tfvars) (and `prod`) to the new `{exp_id}/{run_id}` from the training step, before running:
```sh
make build_monitoring_infra
```

This can take up to 10 minutes.

## Inference
Once it is built you can test the inference using
```sh
make test_endpoint
```

## Test inference locally
If you want to test the model locally you can do so, but first you need to update the `MLFLOW_MODEL_URI` in `app/src/.envtemplate` to match the bucket name holding the MLFlow artifacts and the experiment and run ID. Then rename the file from `.envtemplate` to `.env` and run:
```sh
make launch_local_app
# Run in a new terminal
make predict_local
```

## Teardown
To destroy the resources run (set `ENV` to what you are using in the `tfvar` files):
```sh
make ENV=stg destroy_all
```
This rule first empties all relevant buckets and ECR repositories and then destroys all created terraform resources.
This can take up to 15 minutes.

## TODO:
Some improvements that I have yet to complete:
- [ ] Store EvidentlyAI metrics in AWS RDS and connect to AWS Managed Grafana
- [ ] Add MLFlow run id as SSM parameter for easy access
- [ ] Add new infrastructure directory for "general" infrastructure that is used in multiple infrastructure subdirectories
- [ ] Improve integration tests using localstack
- [ ] Store predictions and input features in new RDS instance
  - Easily added to Sagemaker Endpoint using DataCapture
- [ ] Utilize prefect for triggering workruns better - not just for "monitoring" and logging
- [ ] Add data management/versioning tool (DVC or similar)
