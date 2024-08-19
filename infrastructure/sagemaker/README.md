## Infrastructure for an AWS Sagemaker Endpoint

Creates a Sagemaker Endpoint Configuration, Model and Endpoint itself (`modules/model`), based on an image pushed to ECR (`modules/ecr`). The Docker image is built and pushed in `modules/ecr/main.tf` and the code that is running is found in `app/`. The Docker image starts a FastAPI app which load the model artifacts from S3 using MLFlow on startup (make sure to update `model_id` in `vars/prod.tfvars` with the correct `{exp_id}/{run_id}`.),

The `.env.template` file is for if wanting to run the model locally. See the main `README.md` for instructions.

In addition a number of CloudWatch alarms are created which monitor some endpoint Metrics; CPU, RAM and disk utilization, any 400- or 500-alarms and model latency. These alarms are sent to an SNS-topic, to which one can add an email adress or phone number for notifications. Please note that Terraform does not have the capability to keep track of which subscriptions are confirmed or not, which may cause issues when destroying this resource. See the [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) for more information.

The infra watches a selected number of files (`Dockerfile`, `pyproject.toml`, `poetry.lock`, `nginx.conf` in `app/`, as well as `serve` and all `.py` files in `app/src/`) for changes and will rebuild and push the image if any changes were found.

### Build infra
```sh
terraform init
terraform apply -var-file="vars/staging.tfvars"
```
