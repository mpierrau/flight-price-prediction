"""
Helper functions for model training, tuning and evaluation
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

from typing import Any
from pathlib import Path

import mlflow
import pandas as pd
import numpy.typing as npt
from xgboost import XGBRegressor
from hyperopt import hp
from hyperopt.pyll import scope
from sklearn.metrics import root_mean_squared_error
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import Lasso, Ridge, LinearRegression


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
    static_pars = {}
    match model_name:
        case "LinearRegression":
            model = LinearRegression
            static_pars = {
                "n_jobs": -1,
            }
            search_space = {
                "fit_intercept": hp.choice("fit_intercept", [True, False]),
            }
        case "Lasso":
            model = Lasso
            search_space = {
                "alpha": scope.float(hp.uniform("alpha", 0, 2)),
                "fit_intercept": hp.choice("fit_intercept", [True, False]),
                "max_iter": scope.int(hp.quniform("max_iter", 500, 10000, 1)),
                "tol": scope.float(hp.uniform("tol", 1e-5, 1e-2)),
                "selection": hp.choice("selection", ["cyclic", "random"]),
            }
        case "Ridge":
            model = Ridge
            search_space = {
                "alpha": scope.float(hp.uniform("alpha", 0, 2)),
                "fit_intercept": hp.choice("fit_intercept", [True, False]),
            }
        case "RandomForestRegressor":
            model = RandomForestRegressor
            static_pars = {
                "n_jobs": -1,
            }
            search_space = {
                "max_depth": scope.int(hp.quniform("max_depth", 10, 16, 1)),
                "n_estimators": scope.int(hp.quniform("n_estimators", 25, 45, 1)),
                "min_samples_split": scope.int(hp.quniform("min_samples_split", 2, 10, 1)),
                "min_samples_leaf": scope.int(hp.quniform("min_samples_leaf", 2, 3, 1)),
                "criterion": hp.choice("criterion", ["squared_error", "friedman_mse"]),
            }
        case "XGBRegressor":
            model = XGBRegressor
            static_pars = {
                "device": "cpu",
                "objective": "reg:squarederror",
            }
            search_space = {
                "learning_rate": scope.float(hp.uniform("learning_rate", 0.05, 0.2)),
                "gamma": scope.float(hp.quniform("gamma", 5, 9, 0.1)),
                "max_depth": scope.int(hp.quniform("max_depth", 6, 9, 1)),
                "min_child_weight": scope.int(hp.quniform("min_child_weight", 1, 20, 1)),
                "colsample_bytree": scope.float(hp.uniform("colsample_bytree", 0.6, 1)),
                "n_estimators": scope.int(hp.quniform("n_estimators", 10, 40, 1)),
                "lambda": scope.float(hp.uniform("lambda", 0, 3)),
            }
        case _:
            model = None
            search_space = {}
            static_pars = {}

    return model, static_pars, search_space


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


def prepare_data(
    df_path: Path,
    target_column: str,
) -> tuple[dict[str, Any], npt.ArrayLike]:
    """
    Code for creating training dicts and target arrays.

    Args:
        df (pd.DataFrame): Dataframe with preprocessed data (features)
        target_column (str): Which column is to be used as target.

    Returns:
        tuple[dict[str, Any], npt.ArrayLike[float]]:
            A dictionary with training data entries and an array with corresponding labels
    """
    df = pd.read_parquet(df_path)
    dicts = df.drop(columns=target_column).to_dict(orient="records")
    y_arr = df[target_column].values
    return dicts, y_arr
