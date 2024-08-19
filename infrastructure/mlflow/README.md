## Infrastructure for an AWS hosted MLFlow tracking server
Based off of [this blog post](https://dlabs.ai/blog/how-to-set-up-mlflow-on-aws/#item-15) by D-labs.

Builds and starts an AWS ECS Task (`modules/ecs/`), which runs a Docker image pulled from ECR (`modules/ecr/`) using secrets and parameter values from SSM.
The Docker image is built and pushed in `modules/ecr/main.tf` and the code that is running is found in `src/`.

The infra watches a selected number of files (`Dockerfile`, `pyproject.toml`, `entrypoint.sh` and `mlflow_auth.py` in `src/`) for changes and will rebuild and push the image if any changes were found.

The Docker image starts a MLFlow tracking server which uses an S3 bucket (`modules/s3/`) and RDS to host the backend (`modules/rds/`). The ECS and RDS are hosted in different subnets and in two availability zones. Their communication, as well as load balancing and access from the public internet is setup in `modules/network/`.

Note: By default the infra allows access to the MLFlow API and the DB from the public internet (`0.0.0.0/0`). Both endpoints are protected with passwords, and it's fine for development work and testing, but this is not an advisable setup for a production environment.

### Build infra
```sh
terraform init
terraform apply -var-file="vars/staging.tfvars"
```
