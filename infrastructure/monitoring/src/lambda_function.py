"""
The code run by the AWS Lambda. The code inside lambda_handler
is run each time the lambda is triggered, and the remaining
code is only run once upon startup.

The test data is currently not loaded from anywhere, but is instead
generated on-the-fly (because we don't have regular calls to the
endpoint with new real data.)

In a production environment with production data the download data
call would need to be inside lambda_handler.
"""

import os
import sys
import logging
from typing import Any

from monitoring_svc import MonitoringSvc

MLFLOW_RUN_ID = os.getenv('MLFLOW_RUN_ID')
MLFLOW_MODEL_BUCKET = os.getenv('MLFLOW_MODEL_BUCKET')

MONITORING_DATA_BUCKET = os.getenv('MONITORING_DATA_BUCKET')
MONITORING_TEST_DATA_FILE = os.getenv('MONITORING_TEST_DATA_FILE', None)
MONITORING_REFERENCE_DATA_FILE = os.getenv('MONITORING_REFERENCE_DATA_FILE', None)
MONITORING_REPORT_BUCKET = os.getenv('MONITORING_REPORT_BUCKET')

logger = logging.getLogger()
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

exp_id, run_id = MLFLOW_RUN_ID.split("/")

monitoring_svc = MonitoringSvc(
    logger=logger,
    model_bucket_uri=MLFLOW_MODEL_BUCKET,
    exp_id=exp_id,
    run_id=run_id,
    report_bucket_uri=MONITORING_REPORT_BUCKET,
)

reference_data_path = (
    MONITORING_REFERENCE_DATA_FILE or f"reference_data/train_data_{exp_id}_{run_id}.parquet"
)

monitoring_svc.download_data(
    data_bucket=MONITORING_DATA_BUCKET,
    test_data_file=MONITORING_TEST_DATA_FILE,
    reference_data_file=reference_data_path,
)


def lambda_handler(event: Any, context: Any) -> None:
    """
    Function called by Lambda function. The event and
    context are not used by the method.

    Args:
        event (Any): Unused.
        context (Any): Unused.
    """
    return monitoring_svc.lambda_handler(event, context)


if __name__ == "__main__":
    monitoring_svc.lambda_handler(None, None)
