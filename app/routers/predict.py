"""
A FastAPI wrapper around the prediction model
"""

from http import HTTPStatus
from json import JSONDecodeError
from typing import Any
from logging import Logger

import mlflow
import pandas as pd
from fastapi import Request, APIRouter, HTTPException
from routers.api_models import PredictionPostAPIModel


class Handler:
    """
    A FastAPI wrapper around the prediction model
    """

    def __init__(self, mlflow_model_uri: str, logger: Logger) -> None:
        """
        Args:
            mlflow_model_uri (str): URI to the mlflow model
            logger (Logger): logger object
        """
        self.router = APIRouter()
        self.logger = logger
        self.mlflow_model_uri = mlflow_model_uri

        self.router.add_api_route(
            "/predict",
            self.predict,
            methods=["POST"],
            status_code=HTTPStatus.OK,
        )

        self.load_model(self.mlflow_model_uri)

    def load_model(self, mlflow_model_uri: str) -> None:
        """
        Loads the pipeline from the mlflow uri

        Args:
            mlflow_model_uri (str): uri to the model

        Raises:
            e: MlflowException
        """
        try:
            self.model = mlflow.pyfunc.load_model(mlflow_model_uri)
        except mlflow.MlflowException as e:
            self.logger.error(
                msg="Failed to load model. Exiting.",
                exc_info=True,
            )
            raise e

    async def predict(self, req: Request) -> dict[str, list[dict[str, Any]]]:
        """
        Method for predicting the flight price given a request with
        data.

        Args:
            req (Request): _description_

        Raises:
            HTTPException: _description_
            HTTPException: _description_
            HTTPException: _description_
            HTTPException: _description_

        Returns:
            dict[str, list[dict[str, Any]]]: _description_
        """
        body = await req.body()
        try:
            data = PredictionPostAPIModel.model_validate_json(body)
        except UnicodeDecodeError as e:
            self.logger.error(
                msg="Failed to deserialize JSON body, data is not UTF-8 encoded",
                exc_info=True,
            )
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail=f"Request body must be UTF-8 encoded. Details: {str(e)}",
            ) from e
        except JSONDecodeError as e:
            self.logger.error(
                "Failed to deserialize JSON body",
                exc_info=True,
            )
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail=f"Request body must be valid UTF-8 encoded JSON. Details: {str(e)}",
            ) from e
        except ValueError as e:
            self.logger.error(
                msg="Failed to deserialize JSON body",
                exc_info=True,
            )
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail="Request body validation failed",
            ) from e
        pred_ids = data.prediction_id
        try:
            df = pd.DataFrame(data.model_dump())
        except ValueError as e:
            self.logger.error(
                "Incorrect input data. All data arrays must be of same length.", exc_info=True
            )
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail="Incorrect input data. All data arrays must be of same length.",
            ) from e
        df = df.drop(columns=["prediction_id"])
        preds = self.model.predict(df)
        predictions = [
            {
                'model': 'flight-price-prediction',
                'version': self.mlflow_model_uri,
                'prediction': {
                    'ride_duration': pred.item(),
                    'ride_id': pred_id,
                },
            }
            for pred_id, pred in zip(pred_ids, preds)
        ]
        return {"predictions": predictions}
