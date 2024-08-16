"""
Code for generating an EvidentlyAI report on
performance and data drift
"""

import pathlib

import click
import mlflow
import pandas as pd
import numpy.typing as npt
from evidently import ColumnMapping
from create_new_data import create_random_new_data
from evidently.report import Report
from evidently.metrics import (
    ColumnDriftMetric,
    DatasetDriftMetric,
    DatasetMissingValuesMetric,
)
from evidently.metric_preset import RegressionPreset


def prepare_data(
    df: pd.DataFrame,
    target_column: str | None,
) -> tuple[pd.DataFrame, npt.ArrayLike]:
    """
    Code for creating training data without target, and target arrays.

    Args:
        df (pd.DataFrame): dataframe with data
        target_column (str): Which column is to be used as target.

    Returns:
        tuple[dict[str, Any], npt.ArrayLike[float]]:
            A dictionary with training data entries and an array with corresponding labels
    """
    y_arr = df[target_column].to_numpy()
    df = df.drop(columns=target_column, errors="ignore")
    return df, y_arr


def create_monitoring_report(
    current_data: pd.DataFrame,
    current_data_y: list[float],
    reference_data: pd.DataFrame | None,
    reference_data_y: list[float] | None,
    model_uri: str,
    target_column: str,
    numerical_features: list[str],
    categorical_features: list[str],
) -> Report:
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

    prediction_column = f"predicted_{target_column}"

    if reference_data is not None:
        ref_data_predictions = model.predict(reference_data)
        reference_data.filter(items=[*numerical_features, *categorical_features], axis="columns")
        reference_data[target_column] = reference_data_y
        reference_data[prediction_column] = ref_data_predictions
    else:
        reference_data = None

    current_data_predictions = model.predict(current_data)

    current_data.filter(items=[*numerical_features, *categorical_features], axis="columns")
    current_data[target_column] = current_data_y
    current_data[prediction_column] = current_data_predictions

    column_mapping = ColumnMapping(
        target=target_column,
        prediction=prediction_column,
        numerical_features=numerical_features,
        categorical_features=categorical_features,
    )

    report = create_evidently_regression_report(
        current_data=current_data,
        reference_data=reference_data,
        column_mapping=column_mapping,
    )

    return report


def create_evidently_regression_report(
    current_data: pd.DataFrame, reference_data: pd.DataFrame | None, column_mapping: ColumnMapping
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
            ColumnDriftMetric(column_name=column_mapping.target),
            DatasetDriftMetric(),
            DatasetMissingValuesMetric(),
        ]
    )
    regression_performance.run(
        current_data=current_data, reference_data=reference_data, column_mapping=column_mapping
    )
    return regression_performance


def create_report_from_saved_data(
    test_df: pd.DataFrame | None,
    reference_df: pd.DataFrame | None,
    model_uri: str,
    target_column: str,
    numerical_features: list[str],
    categorical_features: list[str],
    include_invalid_data: bool = False,
    sample_size: int = 200,
    random_seed: int | None = None,
) -> Report:
    """
    Load data or create synthetic data and test it against the given reference data.
    If no reference data is given then a performance report is created.
    Generates evidently AI report.

    Args:
        test_df (pd.DataFrame): Data to monitor for drift
        reference_df (pd.DataFrame): Data to use as reference data.
        model_uri (str): URI to MLFlow model
        target_column (str): Column name of the target variable
        numerical_features (list[str]): Numerical features to use.
        categorical_features (list[str]): Categorical features to use.
        include_invalid_data (bool, optional): Flag for if to generate invalid synthetic
            data or not. Defaults to False.
        sample_size (int, optional): How many synthetic data points to generate. Defaults to 200.
        random_seed (int | None, optional): Random seed for data generation. Defaults to None.
    """
    if test_df is not None:
        test_data, test_data_y = prepare_data(test_df, target_column)
    else:
        test_data = create_random_new_data(sample_size, include_invalid_data, random_seed)
        test_data_y = test_data[target_column].to_numpy()
        test_data.drop(columns=[target_column], inplace=True)

    if reference_df is not None:
        reference_df, reference_data_y = prepare_data(reference_df, target_column)
    else:
        reference_df, reference_data_y = None, None

    report = create_monitoring_report(
        current_data=test_data,
        current_data_y=test_data_y,
        reference_data=reference_df,
        reference_data_y=reference_data_y,
        model_uri=model_uri,
        target_column=target_column,
        numerical_features=numerical_features,
        categorical_features=categorical_features,
    )

    return report


@click.command()
@click.option(
    "-d",
    "--data-to-test-path",
    type=click.Path(exists=True, path_type=pathlib.Path),
    help="Path to data to evaluate.",
)
@click.option(
    "-r",
    "--reference-data-path",
    type=click.Path(exists=True, path_type=pathlib.Path),
    help="Path to used training data/reference data.",
)
@click.option(
    "-m",
    "--model-uri",
    type=str,
    help="MLFlow URI to trained model to use.",
)
@click.option("-t", "--target-column", type=str, default="price", help="Name of target column.")
@click.option(
    "-nfeats",
    "--numerical-features",
    type=list,
    nargs="*",
    default=None,
    help="Name(s) of numerical feature(s) to monitor.",
)
@click.option(
    "-cfeats",
    "--categorical-features",
    type=list,
    nargs="*",
    default=None,
    help="Name(s) of categorical feature(s) to monitor.",
)
@click.option("-g", "--generate-data", is_flag=True, help="Do generate synthetic data to test.")
@click.option(
    "-i",
    "--include-invalid-data",
    is_flag=True,
    help="Generate invalid synthetic data to trigger monitoring.",
)
@click.option(
    "-n", "--sample-size", type=int, default=200, help="How many synthetic samples to generate."
)
@click.option(
    "-s", "--random-seed", type=int, default=13371337, help="Random seed for data generation."
)
def create_report_from_saved_data_wrapper(*args, **kwargs) -> None:
    """
    Argument wrapper function
    """
    create_report_from_saved_data(*args, **kwargs)


if __name__ == '__main__':
    create_report_from_saved_data_wrapper()
