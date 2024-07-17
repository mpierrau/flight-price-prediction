"""
This file contain code for loading and preprocessing the dataset Kaggle Flight Price Prediction Dataset.
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

from pathlib import Path
from prefect import flow, task
import pandas as pd
import logging
import argparse
from prefect.artifacts import create_markdown_artifact
from preprocessing.feature_engineering import (
    create_rounded_arrival_and_departure_times,
    create_total_duration_minutes,
    create_trip_ids,
    create_weekday_feature,
)

logger : logging.Logger = logging.getLogger()
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
    df["Departure_hour_rounded"], df["Arrival_hour_rounded"] = create_rounded_arrival_and_departure_times(df=df)
    df["Total_duration_minutes"] = create_total_duration_minutes(df=df)
    
    return df

@task
def create_table_artifacts(df: pd.DataFrame, num_feats: list[str], cat_feats: list[str], target_column: str) -> None:
    _ = create_markdown_artifact(
        markdown=df[num_feats].describe().to_markdown(),
        description="Summary table of saved features."
        )
    for cat_feat in cat_feats:
        _ = create_markdown_artifact(
            markdown=df[cat_feat].value_counts().to_markdown(),
            description=f"Value count of categorical feature {cat_feat}",
        )
    _ = create_markdown_artifact(
        markdown=df[target_column].describe().to_markdown(),
        description="Summary table of target."
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
        
@flow(log_prints=True)
def preprocess_data(
    path: Path,
    target_column: str,
    categorical_features: list[str],
    numerical_features: list[str],
    savepath: Path,
) -> None:
    df = read_csv_file(path)
    df = feature_engineering(df)
    df = feature_selection(df, categorical_features, numerical_features, target_column)
    
    create_table_artifacts(df, numerical_features, categorical_features, target_column)

    save_dataset(df, savepath)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path, help="Path to data csv file to load.")
    parser.add_argument("-cat-feats", "--categorical_features", type=str, nargs="*", help="Which categorical features to use.")
    parser.add_argument("-num-feats", "--numerical_features", type=str, nargs="*", help="Which numerical features to use.")
    parser.add_argument("--target", type=str, default="Price", help="Target column for predictions.")
    args = parser.parse_args()

    kwargs = {
            "path": args.path,
            "target_column": args.target,
            "categorical_features": args.categorical_features,
            "numerical_features": args.numerical_features,
            "savepath": "data/final_features.csv",
        }
    preprocess_data(
        **kwargs
    )
    # preprocess_data.serve(
    #     tags=["data_preprocessing", "dev:magnus"],
    #     parameters=kwargs,
    # ) # type: ignore
