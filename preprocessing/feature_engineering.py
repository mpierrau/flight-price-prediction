"""
This file contain code for engineering new features
base on the dataset Kaggle Flight Price Prediction Dataset.
Written by Magnus Pierrau for MLOps Zoomcamp Final Project Cohort 2024
"""

import calendar

import pandas as pd


def create_weekday_feature(df: pd.DataFrame) -> pd.Series:
    """
    Function for creating the 'Weekday' feature
    Also removes blank space in source and destination.

    Args:
        df (pd.DataFrame): Dataframe holding columns "Date", "Month"
                            and "Year" as integers or strings.

    Returns:
        pd.Series: Series containing the created feature
    """
    dates = df[["Date", "Month", "Year"]].astype(dtype=str)
    full_date = pd.to_datetime(dates.Year + ' ' + dates.Month + ' ' + dates.Date)
    weekday_abbrs = full_date.apply(lambda x: calendar.day_abbr[x.weekday()])
    return weekday_abbrs


def create_trip_ids(df: pd.DataFrame) -> pd.Series:
    """
    Function for creating the 'trip id' feature.
    Removes blank space in source and destination and concatenates them using an underscore.
    Ex. Banglore_NewDelhi, Delhi_Cochin

    Args:
        df (pd.DataFrame): Dataframe holding columns "Destination" and "Source"

    Returns:
        pd.Series: Series containing the created feature
    """
    destination = df["Destination"].apply(lambda x: x.replace(" ", ""))
    source = df["Source"].apply(lambda x: x.replace(" ", ""))
    trip_ids = source + "_" + destination
    return trip_ids


def create_rounded_arrival_and_departure_times(
    df: pd.DataFrame,
) -> tuple[pd.Series, pd.Series]:
    """
    Function for rounding departure hours and arrival hours to closest full hour
    to reduce cardinality. Ex. 5:44 -> 6, 23:13 -> 23

    Args:
        df (pd.DataFrame): Dataframe holding columns "Dep_hours" "Dep_min",
                            "Arrival_hours" and "Arrival_min"

    Returns:
        tuple[pd.Series[int],pd.Series[int]]: Tuple holding each Series
                                                containing the created feature
    """
    cols = ["Dep_hours", "Dep_min", "Arrival_hours", "Arrival_min"]
    arr_dep_times = df[cols].astype(str)

    dep_closest_full_hour = (
        pd.to_datetime(
            arr_dep_times["Dep_hours"] + ":" + arr_dep_times["Dep_min"], format="%H:%M"
        )
        .dt.round('h')
        .dt.hour
    )
    arr_closest_full_hour = (
        pd.to_datetime(
            arr_dep_times["Arrival_hours"] + ":" + arr_dep_times["Arrival_min"],
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
    duration_hour_as_minutes = df["Duration_hours"] * 60
    total_duration_hours = duration_hour_as_minutes + df["Duration_min"]
    return total_duration_hours
