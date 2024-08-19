"""
Testing the sagemaker wrapper
"""

import json
import uuid
import pprint
import pathlib
from typing import Any

import boto3
import click
from botocore.config import Config
from sagemaker.session import Session
from sagemaker.predictor import Predictor
from sagemaker.serializers import JSONSerializer
from sagemaker.deserializers import JSONDeserializer


class SagemakerPredictor:
    """
    Wraps the sagemaker predict functionality
    """

    def __init__(self, sagemaker_region: str | None, endpoint_name: str | None) -> None:
        """
        Initializes the boto3 sagemaker session, client and predictor

        Args:
            sagemaker_region (str | None): _description_
            endpoint_name (str | None): _description_
        """
        self.sagemaker_region = sagemaker_region
        self.endpoint_name = endpoint_name
        runtime_client = boto3.client(
            "sagemaker-runtime", config=Config(region_name=self.sagemaker_region)
        )
        c = boto3.client("sagemaker", config=Config(region_name=self.sagemaker_region))

        sess = Session(sagemaker_runtime_client=runtime_client, sagemaker_client=c)
        self.predictor = Predictor(
            self.endpoint_name,
            sagemaker_session=sess,
            serializer=JSONSerializer(),
            deserializer=JSONDeserializer(),
        )

    def do_predict(self, prediction_id: str, data: dict[str, list[Any]]) -> dict[str, list[Any]]:
        """
        Sends request to sagemaker endpoint with data.

        Args:
            prediction_id (str): attached to prediction data in AWS
                data capture.
            input (dict[str, list[Any]]): Data to make inference upon.

        Returns:
            dict[str, list[Any]]: Result of model inference.
        """
        return self.predictor.predict(data=data, inference_id=prediction_id)


@click.command()
@click.option(
    "--region", type=str, default="eu-north-1", help="AWS region hosting Sagemaker endpoint"
)
@click.option(
    "--endpoint-name",
    type=str,
    default="flight-price-prediction-endpoint-stg",
    help="Name of Sagemaker endpoint",
)
def prediction_test(
    region: str,
    endpoint_name: str,
) -> None:
    """
    Initializes a predictor, loads test data
    and makes inference through the Sagemaker endpoint.

    Args:
        region (str): AWS region hosting Sagemaker endpoint
        endpoint_name (str): Name of Sagemaker endpoint
    """

    predictor = SagemakerPredictor(
        sagemaker_region=region,
        endpoint_name=endpoint_name,
    )
    pred_id = str(object=uuid.uuid4())
    script_dir = pathlib.Path(__file__).parent.resolve()
    with open(file=script_dir / "data.json", mode="r", encoding="utf-8") as file:
        flight_info = json.load(fp=file)

    res = predictor.do_predict(
        prediction_id=pred_id,
        data=flight_info,
    )

    assert res['predictions']
    pprint.pp(res['predictions'])


if __name__ == "__main__":
    prediction_test()
