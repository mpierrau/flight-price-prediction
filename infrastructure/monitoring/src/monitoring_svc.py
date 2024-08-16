"""
Code for data monitoring service
"""

import logging
import datetime
from random import random
from typing import Any
from pathlib import Path

import boto3
import pandas as pd
from create_report import create_report_from_saved_data
from botocore.exceptions import ClientError


class MonitoringSvc:
    """
    A class which wraps functionality for downloading data
    from S3, loading the inference model, performing
    monitoring analysis and uploading the report to S3.
    """

    def __init__(
        self,
        logger: logging.Logger,
        model_bucket_uri: str,
        exp_id: str,
        run_id: str,
        report_bucket_uri: str,
    ) -> None:
        """
        Constructor for the class. Initializes a boto3 S3 client,
        sets some attributes, constructs the MLFlow Model artifact
        S3 URI and sets the given MLFlow tracking URI.

        Args:
            logger (logging.Logger): Logger object
            model_bucket_uri (str): URI to model artifact
            run_id (str): ID of MLFlow run.
            exp_id (str): ID of MLFlow experiment.
            report_bucket_uri (str): URI to S3 bucket where to save monitoring reports.
        """
        self.__logger = logger
        self.__s3_client = boto3.client("s3")

        self.__mlflow_model_uri = f"s3://{model_bucket_uri}/{exp_id}/{run_id}/artifacts/model"
        self.__reference_data_local_path = None
        self.__test_data_local_path = None
        self.__report_bucket_uri = report_bucket_uri

        self.__tmp = Path("/tmp")

    def download_data(
        self,
        data_bucket: str,
        test_data_file: str | None,
        reference_data_file: str,
    ) -> None:
        """
        Downloads data to be tested and reference data from S3.

        Args:
            data_bucket (str): Bucket name
            test_data_file (str | None): Path to test data in bucket.
            reference_data_file (str): Path to reference data in bucket.
        """
        try:
            if test_data_file is not None:
                self.__test_data_local_path = Path(test_data_file)
                self.__logger.info(
                    f"Downloading test data, saving as {self.__test_data_local_path}"
                )
                self.__s3_client.download_file(
                    Bucket=data_bucket,
                    Key=test_data_file,
                    Filename=self.__tmp / self.__test_data_local_path.name,
                )
        except ClientError as e:
            self.__logger.error("Could not find test data!", exc_info=e)

        try:
            self.__reference_data_local_path = Path(reference_data_file)
            self.__logger.info(
                f"Downloading reference data, saving as {self.__reference_data_local_path}"
            )
            self.__s3_client.download_file(
                Bucket=data_bucket,
                Key=reference_data_file,
                Filename=self.__tmp / self.__reference_data_local_path.name,
            )
        except ClientError as e:
            self.__logger.error("Could not find reference data!", exc_info=e)

    def lambda_handler(self, event: Any, context: Any) -> None:
        """
        The method run by the Lambda function. Inputs not used.
        Reads downloaded data, creates and html and json report,
        saves and uploads it to S3.

        Args:
            event (Any): Not used.
            context (Any): Not used.
        """
        try:
            reference_df = pd.read_parquet(self.__tmp / self.__reference_data_local_path.name)
        except (TypeError, FileNotFoundError) as e:
            self.__logger.error("Could not read reference data", exc_info=e)
            return

        try:
            test_df = pd.read_parquet(self.__tmp / self.__test_data_local_path.name)
        except (TypeError, FileNotFoundError, AttributeError):
            self.__logger.warning("Could not find any test data. Creating synthetic data.")
            # If no path is given or file is not found we will generate
            # synthetic data
            test_df = None

        numerical_features = [
            "total_stops",
            "total_duration_minutes",
            "date",
            "month",
            "year",
            "dep_hours",
            "dep_min",
            "arrival_hours",
            "arrival_min",
            "duration_hours",
            "duration_min",
        ]
        categorical_features = [
            "airline",
            "source",
            "destination",
        ]
        now = datetime.datetime.now().strftime(format="%Y%m%d_%H%M%S")
        try:
            report = create_report_from_saved_data(
                test_df=test_df,  # Set to none to generate synthetic data
                reference_df=reference_df,
                model_uri=self.__mlflow_model_uri,
                target_column='price',
                numerical_features=numerical_features,
                categorical_features=categorical_features,
                include_invalid_data=random() >= 0,  # Randomly make invalid data 10% of the cases
                sample_size=200,
                random_seed=19911991,
            )
        except Exception as e:
            self.__logger.error("Something went wrong when creating report!", exc_info=e)
            raise e

        ref_name = self.__reference_data_local_path.stem
        test_name = (
            f"_{self.__test_data_local_path.stem}"
            if self.__test_data_local_path is not None
            else ""
        )

        report_savepath = self.__tmp / Path(f'report_{ref_name}{test_name}_{now}')

        self.__logger.info(f"Saving report as {report_savepath}(.html/json)")

        report.save_html(filename=f"{report_savepath}.html")
        report.save_json(filename=f"{report_savepath}.json")

        for ext in ["html", "json"]:
            try:
                self.__s3_client.upload_file(
                    Filename=f"{report_savepath}.{ext}",
                    Bucket=self.__report_bucket_uri,
                    Key=f"reports/{report_savepath.stem}.{ext}",
                )
                self.__logger.info(f"Uploaded report {report_savepath.stem}!")
            except ClientError as e:
                self.__logger.error(
                    f"Something went wrong when uploading {ext} report to S3", exc_info=e
                )
                raise e
