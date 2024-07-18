"""
This file contain code for loading and preprocessing the dataset
Kaggle Flight Price Prediction Dataset.
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import logging
import argparse
from pathlib import Path

import pandas as pd
from prefect import flow, task
from prefect.artifacts import create_markdown_artifact
from sklearn.model_selection import train_test_split

from preprocessing.feature_engineering import (
    create_trip_ids,
    create_weekday_feature,
    create_total_duration_minutes,
    create_rounded_arrival_and_departure_times,
)

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
def feature_selection(
    df: pd.DataFrame,
    categorical_features: list[str],
    numerical_features: list[str],
    target_column: str,
) -> pd.DataFrame:
    """
    A function for extracting only specified features from the given dataframe.

    Args:
        df (pd.DataFrame): Dataframe with all features
        categorical_features (list[str]): Which categorical features to include
        numerical_features (list[str]): Which numerical features to include
        target_column (str): Name of target column
    Returns:
        pd.DataFrame: Dataframe containing only relevant features
    """
    df[categorical_features] = df[categorical_features].astype("category")
    df[numerical_features] = df[numerical_features].astype(int)
    df = df.filter(
        items=categorical_features + numerical_features + [target_column],
        axis='columns',
    )
    return df


@task
def feature_engineering(df: pd.DataFrame) -> pd.DataFrame:
    """
    Add a number of new features to the df

    Args:
        df (pd.DataFrame): Dataframe with flight data

    Returns:
        pd.DataFrame: Dataframe with added features
    """
    df["Weekday"] = create_weekday_feature(df=df)
    df["TripID"] = create_trip_ids(df=df)
    df["Departure_hour_rounded"], df["Arrival_hour_rounded"] = (
        create_rounded_arrival_and_departure_times(df=df)
    )
    df["Total_duration_minutes"] = create_total_duration_minutes(df=df)

    return df


@task
def create_table_artifacts(
    df: pd.DataFrame,
    num_feats: list[str],
    cat_feats: list[str],
    target_column: str,
    dataset_name: str,
) -> None:
    """
    Creates a number of table artifacts in prefect,
    saving some dataset info

    Args:
        df (pd.DataFrame): Dataframe to create tables from
        num_feats (list[str]): Names of numerical features
        cat_feats (list[str]): Names of categorical
        target_column (str): Target column, typically "Price"
    """
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
) -> tuple[list, list]:
    """
    Splits given dataframe into a test and train/val split.

    Args:
        df (pd.DataFrame): Dataframe to be splitted
        train_size_frac (float, optional): Fraction to be used for training. Defaults to 0.7.
        random_seed (int, optional): Seed for reproducibility. Defaults to 13371337.

    Returns:
        tuple[list, list]: Tuple with training and test data.
    """
    train_data, test_data = train_test_split(
        df,
        train_size=train_size_frac,
        random_state=random_seed,
        shuffle=True,
    )
    return train_data, test_data


@flow(log_prints=True)
def preprocess_data(
    path: Path,
    target_column: str,
    categorical_features: list[str],
    numerical_features: list[str],
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

    df = read_csv_file(path)
    df = feature_engineering(df)
    df = feature_selection(df, categorical_features, numerical_features, target_column)

    create_table_artifacts(
        df, numerical_features, categorical_features, target_column, "final_features"
    )
    save_dataset(df, savedir / "final_features.parquet")

    data_split: list[pd.DataFrame] = create_test_train_split(
        df=df,
        train_size_frac=train_size,
        random_seed=random_seed,
    )
    test_data, train_data = data_split

    create_table_artifacts(
        test_data, numerical_features, categorical_features, target_column, "test_data"
    )
    create_table_artifacts(
        train_data, numerical_features, categorical_features, target_column, "train_data"
    )

    save_dataset(train_data, savedir / "train_data.parquet")
    save_dataset(test_data, savedir / "test_data.parquet")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path, help="Path to data csv file to load.")
    parser.add_argument(
        "-cat-feats",
        "--categorical_features",
        type=str,
        nargs="*",
        help="Which categorical features to use.",
    )
    parser.add_argument(
        "-num-feats",
        "--numerical_features",
        type=str,
        nargs="*",
        help="Which numerical features to use.",
    )
    parser.add_argument(
        "--target", type=str, default="Price", help="Target column for predictions."
    )
    parser.add_argument(
        "--train-size",
        type=float,
        default=0.7,
        help="Fraction of data to use as training data. \
            Expected to be between 0 and 1. Test size will be 1-(train-size).",
    )
    parser.add_argument(
        "--seed", type=int, default=13371337, help="Random seed for test/train split."
    )
    parser.add_argument(
        "--savedir", type=Path, default="data", help="Directory where to save data to."
    )
    args = parser.parse_args()

    kwargs = {
        "path": args.path,
        "target_column": args.target,
        "categorical_features": args.categorical_features,
        "numerical_features": args.numerical_features,
        "train_size": args.train_size,
        "random_seed": args.seed,
        "savedir": args.savedir,
    }
    preprocess_data(**kwargs)
    # preprocess_data.serve(
    #     tags=["data_preprocessing", "dev:magnus"],
    #     parameters=kwargs,
    # ) # type: ignore
