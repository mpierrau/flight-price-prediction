## Infrastructure for an AWS Lambda for data monitoring
Builds and pushes a Docker container (`modules/ecr/`) which is run by the setup AWS Lambda (`modules/lambda`). The code that is run is that in `src/`, and the command run is the `lambda_handler` function in `src/lambda_function.py`.

The infra watches a selected number of files (`Dockerfile`, `pyproject.toml`, `poetry.lock` and all `.py` files in `src/`) for changes and will rebuild and push the image if any changes were found.

Since we don't receive new updated data from some production environment, the code generates fake input data, and compares it to the training (reference) data, which is uploaded to S3 during the training process. The comparison generates an EvidentlyAI report which is saved in S3 for inspection. The lambda is set to run once daily at noon (UTC), but this is easily changed by altering the CRON-expression in `modules/lambda/main.tf`

### Build lambda infra
```sh
terraform init
terraform apply -var-file="vars/staging.tfvars"
```
