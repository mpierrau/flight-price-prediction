"""
This file contain code for loading and preprocessing the dataset
Kaggle Flight Price Prediction Dataset.
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import logging
import datetime
from pathlib import Path

import click
import pandas as pd
from prefect import flow, task
from prefect.artifacts import create_markdown_artifact
from sklearn.model_selection import train_test_split

logger: logging.Logger = logging.getLogger()
logger.setLevel(level=logging.INFO)


@task
def read_csv_file(path: Path) -> pd.DataFrame:
    """
    A function reading the provided csv file and returning it as a pandas dataframe

    Args:
        path (Path): Path to csv file

    Returns:
        pd.DataFrame: Loaded dataframe
    """
    df: pd.DataFrame = pd.read_csv(
        path,
        engine="pyarrow",
        header="infer",
    )
    return df


@task
def create_table_artifacts(
    df: pd.DataFrame,
    dataset_name: str,
    target_column: str = "price",
) -> None:
    """
    Creates a number of table artifacts in prefect,
    saving some dataset info

    Args:
        df (pd.DataFrame): Dataframe to create tables from
        num_feats (list[str]): Names of numerical features
        cat_feats (list[str]): Names of categorical
        target_column (str): Target column, typically "price"
    """
    num_feats = [
        colname
        for colname, coltype in df.dtypes.items()
        if coltype == "int64" and colname != target_column
    ]
    cat_feats = [
        colname
        for colname, coltype in df.dtypes.items()
        if coltype == "category" and colname != target_column
    ]

    _ = create_markdown_artifact(
        markdown=df[num_feats].describe().to_markdown(),
        description=f"[{dataset_name}]: Summary table of saved features.",
    )
    for cat_feat in cat_feats:
        _ = create_markdown_artifact(
            markdown=df[cat_feat].value_counts().to_markdown(),
            description=f"[{dataset_name}]: Value count of categorical feature {cat_feat}",
        )
    _ = create_markdown_artifact(
        markdown=df[target_column].describe().to_markdown(),
        description=f"[{dataset_name}]: Summary table of target.",
    )


@task
def save_dataset(df: pd.DataFrame, savepath: Path) -> None:
    """
    Save dataframe as parquet.

    Args:
        df (pd.DataFrame): Dataframe to save
        savepath (Path): Path where to save df
    """
    df.to_parquet(
        savepath,
        engine="pyarrow",
        compression=None,
        index=False,
    )


@task
def create_test_train_split(
    df: pd.DataFrame,
    train_size_frac: float = 0.7,
    random_seed: int = 13371337,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """
    Splits given dataframe into a test and train/val split.

    Args:
        df (pd.DataFrame): Dataframe to be splitted
        train_size_frac (float, optional): Fraction to be used for training. Defaults to 0.7.
        random_seed (int, optional): Seed for reproducibility. Defaults to 13371337.

    Returns:
        tuple[list, list]: Tuple with training and test data.
    """
    train_data, validation_data = train_test_split(
        df,
        train_size=train_size_frac,
        random_state=random_seed,
        shuffle=True,
    )
    return train_data, validation_data


@click.command
@click.argument(
    "path",
    type=click.Path(exists=True),
)
@click.option(
    "--train-size",
    type=float,
    default=0.7,
    help="Fraction of data to use as training data. \
        Expected to be between 0 and 1. Test size will be 1-(train-size).",
)
@click.option("--random-seed", type=int, default=13371337, help="Random seed for test/train split.")
@click.option("--savedir", type=Path, default="data", help="Directory where to save data to.")
@flow(log_prints=True)
def preprocess_data(
    path: Path,
    train_size: float,
    random_seed: int,
    savedir: Path,
) -> None:
    """
    Function for loading data, engineering and selecting
    features, creating table artifacts and saving
    the dataset.

    Args:
        path (Path): Path to source data
        target_column (str): Target column name
        categorical_features (list[str]): Categorical feature names
        numerical_features (list[str]): Numerical feature names
        train_size (float): Fraction of data to use as training set.
            Expected to be strictly between 0 and 1.
        random_seed (int): Random seed for reproducing data split.
        savepath (Path): Path where to load and save data.
    """
    assert 0 < train_size < 1, f"Got train_size={train_size}. Must be strictly between 0 and 1."

    target_column = "price"

    now = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    df_raw = read_csv_file(path)
    df_raw.columns = [x.lower() for x in df_raw.columns]

    # The train/val data is created on the dataframe before creating
    # the additional features. This is because we want to include
    # the data preprocessing function in our sklearn pipeline
    # in the training process.
    data_split = create_test_train_split(
        df=df_raw,
        train_size_frac=train_size,
        random_seed=random_seed,
    )
    validation_data, train_data = data_split

    create_table_artifacts(
        validation_data,
        "validation_data",
        target_column,
    )
    create_table_artifacts(
        train_data,
        "train_data",
        target_column,
    )

    save_dataset(train_data, savedir / f"train_data_{now}.parquet")
    save_dataset(validation_data, savedir / f"validation_data_{now}.parquet")


if __name__ == "__main__":
    preprocess_data()
