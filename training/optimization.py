"""
Code for hyperparameter optimization
"""

import os
from typing import Any
from pathlib import Path

import click
import numpy as np
from prefect import flow
from hyperopt import STATUS_OK, Trials, tpe, fmin

from training.utils import prepare_data, setup_experiment, get_model_and_params
from training.train_model import train_and_evaluate

MLFLOW_TRACKING_URI = os.getenv("MLFLOW_URI", "")
EXPERIMENT_NAME = os.getenv("EXPERIMENT_NAME", "flight-price-prediction")
DEVELOPER_NAME = os.getenv("DEVELOPER_NAME", "magnus")


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
    "--model-name",
    type=click.Choice(
        choices=["LinearRegression", "Lasso", "Ridge", "RandomForestRegressor", "XGBRegressor"]
    ),
    help="Model name to train",
)
@click.option(
    "--num-trials",
    default=15,
    help="The number of parameter evaluations for the optimizer to explore",
)
@click.option(
    "--loss-key",
    type=str,
    default="rmse",
    help="Which metric to use as loss for optimization.",
)
@click.option(
    "--target-column",
    type=str,
    default="price",
    help="Name of column to predict",
)
@click.option(
    "--seed",
    type=int,
    default=13371337,
    help="Random seed for reproducibility",
)
@flow
def run_optimization(
    train_data_path: Path,
    val_data_path: Path,
    model_name: str,
    num_trials: int,
    loss_key: str,
    target_column: str,
    seed: int,
) -> None:
    """
    Sets up mlflow tracking, prepares training and validation data,
    fetches model and related parameter search space.
    Performs hyperpar optimization using bayesian search tool hyperopt.
    Logs all runs but does not save any model artifacts.

    Args:
        train_data_path (Path): Path to training data
        val_data_path (Path): Path to validation data
        model_name (str): Name of model, must be one of
            those specified in get_model_and_params
        num_trials (int): How many hp trials with different
            hyperpars to run
        loss_key (str): Which metric to minimize wrt
        target_column (str): Column to use as target
        seed (int): Random seed for reproducibility
    """
    _, exp_id = setup_experiment(
        experiment_name=EXPERIMENT_NAME,
        tracking_uri=MLFLOW_TRACKING_URI,
    )
    # Load data
    train_data = prepare_data(train_data_path, target_column)
    val_data = prepare_data(val_data_path, target_column)

    model_class, static_pars, search_space = get_model_and_params(model_name)
    pars_to_log = {
        "train-data-path": train_data_path,
        "val-data-path": val_data_path,
        "seed": seed,
    }

    def objective(params: dict[str, Any]) -> dict[str, float | str]:
        """
        Objective for hpo to minimize.

        Args:
            params (dict[str, Any): Model parameters
                (changes between hpo runs)

        Returns:
            dict[str, float | str]: Dict with metrics and status for hpo
        """
        metric_dict = train_and_evaluate(
            model_class=model_class,
            model_pars={**params, **static_pars},
            train_data=train_data,
            val_data=val_data,
            experiment_id=exp_id,
            pars_to_log=pars_to_log,
            log_model=False,
        )
        return {"loss": metric_dict[loss_key], "status": STATUS_OK}

    rstate = np.random.default_rng(seed=seed)  # for reproducible results
    fmin(
        fn=objective,
        space=search_space,
        algo=tpe.suggest,
        max_evals=num_trials,
        trials=Trials(),
        rstate=rstate,
    )


if __name__ == "__main__":
    run_optimization()
