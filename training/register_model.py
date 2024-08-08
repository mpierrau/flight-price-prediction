"""
Code for replicating top_n hyperpartuning runs,
saving them to mlflow with model artifacts and
promoting the best one to the model registry.
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import os
import sys
import logging
from pathlib import Path

import tqdm
import click
import mlflow
from prefect import flow
from mlflow.entities import Run, ViewType
from mlflow.tracking import MlflowClient

from training.utils import prepare_data, setup_experiment, get_model_and_params
from training.train_model import train_and_evaluate

MLFLOW_EXPERIMENT_NAME = os.getenv("MLFLOW_EXPERIMENT_NAME", "flight-price-prediction")
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_URI", "")
DEVELOPER_NAME = os.getenv("DEVELOPER_NAME", "magnus")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


@click.command()
@click.argument(
    "train-data-path",
    type=click.Path(exists=True),
)
@click.argument(
    "val-data-path",
    type=click.Path(exists=True),
)
@click.option(
    "-n",
    "--top_n",
    default=5,
    type=int,
    help="Number of top models that need to be evaluated to decide which one to promote",
)
@click.option(
    "-e",
    "--exp-name",
    type=str,
    default="flight-price-prediction",
    help="Name of MLFlow experiment",
)
@click.option(
    "-uri",
    "--mlflow-tracking-uri",
    type=str,
    help="MLFlow tracking URI",
)
@click.option(
    "-t",
    "--target-column",
    type=str,
    default="price",
    help="Name of column to predict",
)
@click.option(
    "-s",
    "--seed",
    type=int,
    default=13371337,
    help="Random seed for reproducibility",
)
@flow
def run_register_model(
    train_data_path: Path,
    val_data_path: Path,
    top_n: int,
    exp_name: str,
    mlflow_tracking_uri: str | None,
    target_column: str,
    seed: int,
) -> None:
    """
    Function for replicating top_n hyperpartuning runs,
    saving them to mlflow with model artifacts and
    promoting the best one to the model registry.

    Args:
        train_data_path (Path): Training data
        val_data_path (Path): Validation data
        top_n (int): How many runs to rerun
        exp_name (str): Name of mlflow experiment
        mlflow_tracking_uri (str | None): mlflow tracking uri.
        target_column (str): which column to use as target
        seed (int): random seed for reproducibility
    """
    logger.info("Preparing data")
    train_data = prepare_data(train_data_path, target_column)
    val_data = prepare_data(val_data_path, target_column)

    logger.info(
        "Starting MlflowClient with tracking uri %s", mlflow_tracking_uri or MLFLOW_TRACKING_URI
    )
    client = MlflowClient(tracking_uri=mlflow_tracking_uri or MLFLOW_TRACKING_URI)

    logger.info(
        "Getting top %s runs from experiment %s", top_n, (exp_name or MLFLOW_EXPERIMENT_NAME)
    )
    # Retrieve the top_n model runs and log the models
    experiment = client.get_experiment_by_name(exp_name or MLFLOW_EXPERIMENT_NAME)
    if not experiment:
        runs = []
    else:
        runs = client.search_runs(
            experiment_ids=experiment.experiment_id,
            run_view_type=ViewType.ACTIVE_ONLY,
            max_results=top_n,
            order_by=["metrics.rmse ASC"],
        )
    logger.info("Found %s runs", len(runs))
    pars_to_log: dict[str, Path | int] = {
        "train-data-path": train_data_path,
        "val-data-path": val_data_path,
    }
    new_exp_name = MLFLOW_EXPERIMENT_NAME + "_best_runs"
    client, exp_id = setup_experiment(
        experiment_name=new_exp_name,
        tracking_uri=MLFLOW_TRACKING_URI,
    )
    logger.info("Starting experiment runs")
    for run in tqdm.tqdm(runs):
        model_class, static_pars, search_space = get_model_and_params(run.data.tags['model_name'])
        model_pars = {k: v for k, v in run.data.params.items() if k in search_space}
        for param in search_space:
            try:
                par_as_str = model_pars[param]
                if float(par_as_str) == int(par_as_str):
                    model_pars[param] = int(par_as_str)
                else:
                    model_pars[param] = float(par_as_str)
            except ValueError:
                # Some pars are strings
                pass
        _ = train_and_evaluate(
            model_class=model_class,
            model_pars={**model_pars, **static_pars, "seed": seed},
            train_data=train_data,
            val_data=val_data,
            experiment_id=exp_id,
            pars_to_log=pars_to_log,
            log_model=True,
        )
    logger.info("Finding best run")
    # Select the model with the lowest test RMSE
    experiment = client.get_experiment_by_name(name=new_exp_name)
    if not experiment:
        print(f"Experiment not found {new_exp_name}!")
        sys.exit()

    best_run: Run = client.search_runs(
        experiment_ids=experiment.experiment_id,
        run_view_type=ViewType.ACTIVE_ONLY,
        max_results=1,
        order_by=["metrics.rmse ASC"],
    )[0]

    logger.info("Registering model to registry")
    # Register the best model
    mlflow.register_model(
        model_uri=f"runs:/{best_run.info.run_id}/model",
        name=f"{MLFLOW_EXPERIMENT_NAME}-best-model",
    )
    logger.info("Done, model id: %s", f"{best_run.info.experiment_id}/{best_run.info.run_id}")


if __name__ == "__main__":
    run_register_model()
