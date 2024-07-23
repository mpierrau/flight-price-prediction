"""
This file contain code for engineering new features
base on the dataset Kaggle Flight Price Prediction Dataset.
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import calendar

import pandas as pd


def create_weekday_feature(df: pd.DataFrame) -> pd.Series:
    """
    Function for creating the 'weekday' feature
    Also removes blank space in source and destination.

    Args:
        df (pd.DataFrame): Dataframe holding columns "date", "month"
                            and "year" as integers or strings.

    Returns:
        pd.Series: Series containing the created feature
    """
    dates = df[["date", "month", "year"]].astype(dtype=str)
    full_date = pd.to_datetime(dates.year + ' ' + dates.month + ' ' + dates.date)
    weekday_abbrs = full_date.apply(lambda x: calendar.day_abbr[x.weekday()])
    return weekday_abbrs


def create_trip_ids(df: pd.DataFrame) -> pd.Series:
    """
    Function for creating the 'trip id' feature.
    Removes blank space in source and destination and concatenates them using an underscore.
    Ex. Banglore_NewDelhi, Delhi_Cochin

    Args:
        df (pd.DataFrame): Dataframe holding columns "destination" and "source"

    Returns:
        pd.Series: Series containing the created feature
    """
    destination = df["destination"].apply(lambda x: x.replace(" ", ""))
    source = df["source"].apply(lambda x: x.replace(" ", ""))
    trip_ids = source + "_" + destination
    return trip_ids


def create_rounded_arrival_and_departure_times(
    df: pd.DataFrame,
) -> tuple[pd.Series, pd.Series]:
    """
    Function for rounding departure hours and arrival hours to closest full hour
    to reduce cardinality. Ex. 5:44 -> 6, 23:13 -> 23

    Args:
        df (pd.DataFrame): Dataframe holding columns "dep_hours" "dep_min",
                            "arrival_hours" and "arrival_min"

    Returns:
        tuple[pd.Series[int],pd.Series[int]]: Tuple holding each Series
                                                containing the created feature
    """
    cols = ["dep_hours", "dep_min", "arrival_hours", "arrival_min"]
    arr_dep_times = df[cols].astype(str)

    dep_closest_full_hour = (
        pd.to_datetime(
            arr_dep_times["dep_hours"] + ":" + arr_dep_times["dep_min"],
            format="%H:%M",
        )
        .dt.round('h')
        .dt.hour
    )
    arr_closest_full_hour = (
        pd.to_datetime(
            arr_dep_times["arrival_hours"] + ":" + arr_dep_times["arrival_min"],
            format="%H:%M",
        )
        .dt.round('h')
        .dt.hour
    )

    return dep_closest_full_hour, arr_closest_full_hour


def create_total_duration_minutes(df: pd.DataFrame) -> pd.Series:
    """
    Sum duration hours and minutes into total minutes.
    Ex. 2 hours 30 mins = 150 minutes

    Args:
        df (pd.DataFrame): _description_

    Returns:
        pd.Series: Series containing the created feature
    """
    duration_hour_as_minutes = df["duration_hours"] * 60
    total_duration_hours = duration_hour_as_minutes + df["duration_min"]
    return total_duration_hours


def feature_selection(
    df: pd.DataFrame,
) -> pd.DataFrame:
    """
    A function for extracting only specified features from the given dataframe.

    Args:
        df (pd.DataFrame): Dataframe with all features
        categorical_features (list[str] | None): Which categorical features to include.
            Defaults to None.
        numerical_features (list[str] | None): Which numerical features to include.
            Defaults to None.
        target_column (str | None): Name of target column. Defaults to None.
    Returns:
        pd.DataFrame: Dataframe containing only relevant features
    """
    categorical_features = [
        "airline",
        "weekday",
        "tripid",
        "departure_hour_rounded",
        "arrival_hour_rounded",
    ]
    numerical_features = [
        "total_stops",
        "total_duration_minutes",
    ]
    target_column = "price"

    df[categorical_features] = df[categorical_features].astype("category")
    df[numerical_features] = df[numerical_features].astype(int)
    df = df.filter(
        items=categorical_features + numerical_features + [target_column],
        axis="columns",
    )
    return df


def feature_engineering(df: pd.DataFrame) -> pd.DataFrame:
    """
    Add a number of new features to the df and make it into a dict

    Args:
        df (pd.DataFrame): Dataframe with flight data

    Returns:
        pd.DataFrame: Dataframe with added features
    """
    df["weekday"] = create_weekday_feature(df=df)
    df["tripid"] = create_trip_ids(df=df)
    df["departure_hour_rounded"], df["arrival_hour_rounded"] = (
        create_rounded_arrival_and_departure_times(df=df)
    )
    df["total_duration_minutes"] = create_total_duration_minutes(df=df)

    return df


def preprocessing_pipeline(
    df_raw: pd.DataFrame,
) -> list[dict]:
    """
    Combo of feature engineering and selection and
    final transformation into a list of dicts

    Args:
        df_raw (pd.DataFrame): Data to process

    Returns:
        list[dict]: List of dictionaries
    """
    df = feature_engineering(df_raw.copy())
    df = feature_selection(df)
    return df.to_dict(orient="records")
