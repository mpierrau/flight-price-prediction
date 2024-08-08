"""
Code for training and evaluating model
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import os
from typing import Any
from pathlib import Path

import mlflow
import pandas as pd
import numpy.typing as npt
from prefect import task
from sklearn.pipeline import FunctionTransformer, make_pipeline
from feature_engineering import preprocessing_pipeline
from sklearn.feature_extraction import DictVectorizer

from training.utils import calculate_metrics

MLFLOW_TRACKING_URI = os.getenv("MLFLOW_URI", "")
MLFLOW_EXPERIMENT_NAME = os.getenv("MLFLOW_EXPERIMENT_NAME", "flight-price-prediction")
DEVELOPER_NAME = os.getenv("DEVELOPER_NAME", "magnus")


@task
def train_model(
    model: Any,
    X_train: pd.DataFrame,
    y_train: npt.ArrayLike,
) -> Any:
    """
    Training the given model or pipeline simply
    using the method fit

    Args:
        model (Any): a model or sklearn pipeline
        X_train (pd.DataFrame): dictionary with data entries
        y_train (npt.ArrayLike): array with target values

    Returns:
        Any: the trained model
    """
    fit_model = model.fit(X_train, y_train)
    return fit_model


@task
def evaluate_model(
    model: Any,
    X_val: pd.DataFrame,
    y_val: npt.ArrayLike,
) -> dict[str, float]:
    """
    Code for predicting and evaluating the performance

    Args:
        model (Any): model or pipeline to predict with
        X_val (pd.DataFrame): Test/validation data
        y_val (npt.ArrayLike): Test/validation ground truth values

    Returns:
        dict[str, float]: A dictionary with metric names and values
    """
    y_pred = model.predict(X_val)
    return calculate_metrics(predicted=y_pred, actual=y_val)


@task
def train_and_evaluate(
    model_class: Any,
    model_pars: dict,
    train_data: tuple[pd.DataFrame, npt.ArrayLike],
    val_data: tuple[pd.DataFrame, npt.ArrayLike],
    experiment_id: str,
    pars_to_log: dict[str, Path | int],
    log_model: bool = False,
) -> dict[str, float]:
    """

    Args:
        model_class (Any): Model class to use.
        model_pars (dict): Model parameters.
        train_data (tuple[dict, npt.ArrayLike]): A tuple with training data and ground truth array
        val_data (tuple[dict, npt.ArrayLike]): A tuple with validation data and ground truth array
        experiment_id (str): MLFlow experiment id for tracking
        pars_to_log (dict): MLFlow tracking id for tracking
        log_model (bool): Whether to save model artifacts to mlflow.
            Good to not do during hyperopt tuning.
    """
    # Create a pipeline with preprocessing, vectorizer and model
    model_instance = model_class(**model_pars)
    pipeline = make_pipeline(
        FunctionTransformer(preprocessing_pipeline, validate=False),
        DictVectorizer(),
        model_instance,
    )

    with mlflow.start_run(experiment_id=experiment_id):
        mlflow.set_tag("developer", DEVELOPER_NAME)
        mlflow.set_tag("model_name", model_instance.__class__.__name__)
        mlflow.log_params(pars_to_log)
        mlflow.log_params(model_pars)

        trained_pipeline = train_model(pipeline, *train_data)
        metrics = evaluate_model(trained_pipeline, *val_data)

        mlflow.log_metrics(metrics)
        if log_model:
            input_example = train_data[0].sample(n=1)
            mlflow.sklearn.log_model(
                pipeline,
                artifact_path="model",
                input_example=input_example,
                code_paths=["training/feature_engineering.py"],
            )

    return metrics
