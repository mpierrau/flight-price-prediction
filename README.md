# flight-price-prediction
My Final Project for the DataTalks MLOPS Zoomcamp 2024.
Prerequisites:
- AWS Account
- Prefect Cloud Account (create one for free [here]((https://docs.prefect.io/2.14.2/getting-started/quickstart/#step-2-connect-to-prefects-api)))
Developed on Ubuntu 23.10 and 24.04.

The preprocessing and training is monitored/logged using `prefect`. All runs can be reviewed using the Prefect Cloud UI.

All infrastructure is managed by Terraform. If anything fails during the `apply` stage the issue may resolve itself by running `terraform apply` (or the `make` command) one more time. If the error persists then something else is the issue.

## Setup

### Dependency installation
1. Install [`poetry`](https://python-poetry.org/docs/)
2. Install the [`aws cli v2`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. Install [`terraform`](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
4. Navigate to the root folder (`flight-price-prediction/`) and install package dependencies:
```sh
make setup
```
5. Go to the following files and change `mpierrau` to some other unique identifier (the S3 bucket name needs to be unique across all of the internet):
  - `flight-price-prediction/infrastructure/mlflow/main.tf`
  - `flight-price-prediction/infrastructure/sagemaker/main.tf`
  - `flight-price-prediction/infrastructure/monitoring/main.tf`
```terraform
terraform {
  ...
  backend "s3" {
    bucket = "tf-state-flight-price-prediction-mpierrau"
    ...
  }
}
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

We also need some infra for training, tracking and monitoring (and S3 bucket and ECR repo):
```sh
make build_data_infra
```

## Preprocessing
Performs feature engineering and creates train/test split of the data.
```sh
make preprocess_data
```

## Training
First we do some local hyperparameter tuning on the data. Default is 50 runs, which takes a couple of minutes, depending on your machine. With the given seeds we get a model with a lowest loss of ~1900. We only log the metadata of these models - no artifacts.
```sh
make train_model_hyperpar_search
```
Then we locally train and register the 3 best models. The models that are saved are actually pipelines which performs feature engineering and feature selection before the inference step. These all get their artifacts uploaded to S3 via MLFlow. We also upload training script and feature engineering for tracability.
```sh
make register_model
```

Once the models are registered, the model id of the model with the lowest loss will be printed in the terminal. Take the Experiment ID and Run ID and replace the current value of `model_id` in `infrastructure/sagemaker/vars/prod.tfvars` with the new values as `'{experiment_id}/{model_id}'`.

If you want to head to the MLFlow UI to find another model ID follow the instructions below.

### To open the AWS MLFlow UI
Run:
```sh
make get_mlflow_info
```
Go to the returned DNS adress in a browser and enter the username and password (these were automatically generated during the build process and are stored in AWS SSM).

## Serving
Serve the model via an Sagemaker Endpoint and build related Cloudwatch alarms and a Subscribable SNS topic. If you wish to add your email to the subscription, append your email to the list `alarm_subscribers` in `infrastructure/sagemaker/vars/prod.tfvars`. Then run:
```sh
make build_sagemaker_infra
```
You will receive a confirmation email in which you need to confirm the subscription. Please note that Terraform does not have the capability to keep track of which subscriptions are confirmed or not, which may cause issues when destroying this resource if the subscription has not been confirmed. See the [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) for more information.

## Monitoring
Builds an AWS Lambda function which creates an EvidentlyAI report once daily and uploads it to an S3 bucket.
The link to the S3 bucket is outputted as `report_bucket` once this command has successfully completed.

Here, again you are required to update `mlflow_run_id` in `infrastructure/monitoring/vars/prod.tfvars` to the new `'{exp_id}/{run_id}'` from the training step, before running:
```sh
make build_monitoring_infra
```

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
