"""
Code for training and evaluating model
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import os
from typing import Any
from pathlib import Path

import click
import mlflow
import pandas as pd
import numpy.typing as npt
from prefect import flow, task
from sklearn.pipeline import make_pipeline
from sklearn.feature_extraction import DictVectorizer

from training.utils import setup_experiment, calculate_metrics, get_model_and_params

MLFLOW_TRACKING_URI = os.getenv("MLFLOW_URI")
EXPERIMENT_NAME = os.getenv("EXPERIMENT_NAME")


@task
def train_model(
    model: Any,
    X_train: dict,
    y_train: npt.ArrayLike,
) -> Any:
    """
    Training the given model or pipeline simply
    using the method fit

    Args:
        model (Any): a model or sklearn pipeline
        X_train (dict): dictionary with data entries
        y_train (npt.ArrayLike): array with target values

    Returns:
        Any: the trained model
    """
    fit_model = model.fit(X_train, y_train)
    return fit_model


@task
def evaluate_model(
    model: Any,
    X_val: npt.ArrayLike,
    y_val: npt.ArrayLike,
) -> dict[str, float]:
    """
    Code for predicting and evaluating the performance

    Args:
        model (Any): model or pipeline to predict with
        X_val (npt.ArrayLike): Test/validation data
        y_val (npt.ArrayLike): Test/validation ground truth values

    Returns:
        dict[str, float]: A dictionary with metric names and values
    """
    y_pred = model.predict(X_val)
    return calculate_metrics(predicted=y_pred, actual=y_val)


@task
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
    dicts = df.drop(columns=target_column).to_dict(orient='records')
    y_arr = df[target_column].values
    return dicts, y_arr


@click.command()
@click.argument("train_data_path", type=click.Path(exists=True))
@click.argument("val_data_path", type=click.Path(exists=True))
@click.option(
    "-m",
    "--model_name",
    type=click.Choice(choices=["LinearRegression", "Lasso", "Ridge"]),
    help="Which model type to train.",
)
@click.option("-t", "--target_column", type=str, default="Price", help="Target column name.")
@flow
def train_and_evaluate(
    train_data_path: Path,
    val_data_path: Path,
    target_column: str,
    model_name: str,
) -> None:
    """
    Trains specified model on specified training data with given
    target column as target, and evaluates on specified validation data.
    Tracked on mlflow server with given uri and exp name.

    Args:
        train_data_path (Path): Path to training data parquet
        val_data_path (Path): Path to validation data parquet
        target_column (str): Column to use as target
        model_name (str): Name of sklearn model class.
        experiment_name (str | None, optional):
            Mlflow tracking experiment name. Defaults to None.
        mlflow_tracking_uri (str | None, optional):
            Mlflow tracking URI (include protocol and port). Defaults to None.
    """
    _, exp_id = setup_experiment(
        experiment_name=EXPERIMENT_NAME,
        tracking_uri=MLFLOW_TRACKING_URI,
    )
    # Load data
    train_dicts, y_train = prepare_data(train_data_path, target_column)
    val_dicts, y_val = prepare_data(val_data_path, target_column)

    # Setup vectorizer and model
    dv = DictVectorizer()
    model_class, model_params = get_model_and_params(model_name=model_name)

    # Create a pipeline
    pipeline = make_pipeline(
        dv,
        model_class(**model_params),
    )
    # -1 means use all available processors for multiproc when fitting and predicting

    with mlflow.start_run(experiment_id=exp_id):
        mlflow.set_tag("developer", "magnus")
        mlflow.log_param("train-data-path", train_data_path)
        mlflow.log_param("val-data-path", val_data_path)
        mlflow.log_params(params=model_params)

        trained_pipeline = train_model(pipeline, train_dicts, y_train)
        metrics = evaluate_model(trained_pipeline, val_dicts, y_val)

        mlflow.log_metrics(metrics=metrics)
        mlflow.sklearn.log_model(pipeline, artifact_path="model")


if __name__ == '__main__':
    train_and_evaluate()
