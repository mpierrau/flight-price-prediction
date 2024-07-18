"""
Helper functions for model training, tuning and evaluation
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

from typing import Any

import mlflow
from sklearn.metrics import root_mean_squared_error
from sklearn.linear_model import Lasso, Ridge, LinearRegression

# def hyperpar_tuning(): ...


def get_model_and_params(
    model_name: str,
) -> tuple[type[LinearRegression] | type[Lasso] | type[Ridge]]:
    """
    Returns models and parameters depending on given string. Iniitial solution.

    Args:
        model_name (str): Model to use. Accepted choices: "LinearRegression", "Lasso" and "Ridge".
                            If anything else is given will use LinearRegression with default pars.

    Returns:
        tuple[type[LinearRegression] | type[Lasso] | type[Ridge]]: Tuple with model and parameters
    """
    match model_name:
        case "LinearRegression":
            model = LinearRegression
            params = {
                "fit_intercept": True,
                "njobs": -1,
            }
        case "Lasso":
            model = Lasso
            params = {
                "alpha": 0.1,
                "fit_intercept": True,
                "max_iter": 10000,
            }
        case "Ridge":
            model = Ridge
            params = {
                "alpha": 0.1,
                "fit_intercept": True,
            }
        case _:
            model = LinearRegression
            params = {}

    return model, params


def calculate_metrics(predicted: list[Any], actual: list[Any]) -> dict[str, float]:
    """
    Calculate metrics of the model predictions.

    Args:
        predicted (list[Any]): Predicted values
        actual (list[Any]): Ground truth

    Returns:
        dict[str, float]: Dictionary with calculated metrics
    """
    rmse = root_mean_squared_error(actual, predicted)
    metric_dict = {
        "rmse": rmse,
    }
    return metric_dict


def setup_experiment(
    experiment_name: str | None = None,
    tracking_uri: str | None = None,
) -> tuple[mlflow.MlflowClient, str]:
    """
    Helper method for setting up a mlflow experiment and returning client and id

    Args:
        experiment_name (str | None, optional): Name of experiment. Defaults to None.
        tracking_uri (str | None, optional): MLFlow tracking uri (including protocol and port).
                                                Defaults to None.

    Returns:
        tuple[mlflow.MlflowClient, str]: mlflow client and experiment id
    """
    mlflow.set_tracking_uri(tracking_uri)

    client = mlflow.MlflowClient()
    experiment = client.get_experiment_by_name(experiment_name)

    if experiment:
        experiment_id = experiment.experiment_id
    else:
        experiment_id = client.create_experiment(experiment_name)

    return client, experiment_id
