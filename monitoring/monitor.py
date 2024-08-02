"""
Code for generating an EvidentlyAI report on
performance and data drift
"""

import pathlib
from pathlib import Path

import click
import mlflow
import pandas as pd
from evidently import ColumnMapping
from evidently.report import Report
from evidently.metrics import (
    ColumnDriftMetric,
    DatasetDriftMetric,
    DatasetMissingValuesMetric,
)
from evidently.metric_preset import RegressionPreset

from training.utils import prepare_data

MLFLOW_MODEL_URI = (
    "s3://mlflow-models-magnus-dev/5/02ab125dbc784fd19d21159287170fa0/artifacts/model/"
)


@click.command()
@click.argument("data-to-test-path", type=click.Path(exists=True, path_type=pathlib.Path))
@click.option(
    "--reference-data-path",
    type=click.Path(exists=True, path_type=pathlib.Path),
    help="Path to used training data/reference data.",
)
@click.option(
    "--model-uri", type=str, default=MLFLOW_MODEL_URI, help="MLFlow URI to trained model to use."
)
@click.option("--target-column", type=str, default="price", help="Name of target column.")
@click.option(
    "--numerical-features",
    type=list,
    nargs="*",
    default=None,
    help="Name(s) of numerical feature(s) to monitor.",
)
@click.option(
    "--categorical-features",
    type=list,
    nargs="*",
    default=None,
    help="Name(s) of categorical feature(s) to monitor.",
)
def main(
    data_to_test_path: Path,
    reference_data_path: Path | None,
    model_uri: str,
    target_column: str,
    numerical_features: list[str],
    categorical_features: list[str],
) -> None:
    """
    Creates a default regression evidently report for the given data. If the reference
    data is omitted, the report will be on regression performance for the given dataset,
    without any comparison between datasets.

    If a reference dataset is given it will use this as a baseline and also consider data
    drift and similar.

    Outputs an html report

    Args:
        data_to_test_path (Path): Path to used training data/reference data
        reference_dath_path (Path): Path to data to validate against reference data.
        model_uri (str): URI to MLFlow model
        target_column (str): Column name of the target variable
        numerical_features (list[str]): Numerical features to use.
        categorical_features (list[str]): Categorical features to use.
    """
    model = mlflow.pyfunc.load_model(model_uri)

    target_column = target_column or "price"
    prediction_column = f"predicted_{target_column}"

    colmap_args = {
        "target": target_column,
        "prediction": prediction_column,
        "numerical_features": numerical_features
        or [
            "total_stops",
            "total_duration_minutes",
        ],
        "categorical_features": categorical_features
        or [
            "airline",
            "weekday",
            "tripid",
            "departure_hour_rounded",
            "arrival_hour_rounded",
        ],
    }

    if reference_data_path:
        reference_data, reference_data_y = prepare_data(reference_data_path, target_column)
        ref_data_predictions = model.predict(reference_data)
        reference_data.filter(items=[numerical_features, categorical_features], axis="columns")
        reference_data[prediction_column] = ref_data_predictions
        reference_data[target_column] = reference_data_y
    else:
        reference_data = None

    current_data, current_data_y = prepare_data(data_to_test_path, target_column)
    current_data_predictions = model.predict(current_data)

    current_data.filter(items=[numerical_features, categorical_features], axis="columns")
    current_data[prediction_column] = current_data_predictions
    current_data[target_column] = current_data_y

    # Initial performance
    report = create_evidently_report(
        current_data=current_data, reference_data=reference_data, column_mapping_args=colmap_args
    )
    ref_data_str = f"_{reference_data_path.stem}" if reference_data_path is not None else ""
    report_savename = f"regression_performance_at_training_{data_to_test_path.stem}{ref_data_str}"
    report.save_html(filename=f"monitoring/reports/{report_savename}.html")


def create_evidently_report(
    current_data: pd.DataFrame, reference_data: pd.DataFrame | None, column_mapping_args: dict
) -> Report:
    """
    Returns an EvidentlyAI report with some hardcoded metrics for the regression task.

    Args:
        current_data (pd.DataFrame): Data to test for performance and drift
        reference_data (pd.DataFrame | None): Reference/baseline data to compare against
        column_mapping_args (dict): Keyword args for the ColumnMapping object

    Returns:
        Report: An evidently report object
    """
    regression_performance = Report(
        metrics=[
            RegressionPreset(),
            ColumnDriftMetric(column_name=column_mapping_args["target"]),
            DatasetDriftMetric(),
            DatasetMissingValuesMetric(),
        ]
    )
    column_mapping = ColumnMapping(**column_mapping_args)
    regression_performance.run(
        current_data=current_data, reference_data=reference_data, column_mapping=column_mapping
    )
    return regression_performance


if __name__ == '__main__':
    main()
