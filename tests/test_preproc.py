"""
Unit tests for preprocessing code
"""

import pandas as pd
import deepdiff
from prefect.testing.utilities import prefect_test_harness

from preprocessing.preprocess_data import feature_selection, feature_engineering


def test_preprocess_data() -> None:
    """
    Test feature engineering and selection functions
    """
    test_data = {
        "Date": [6, 17],
        "Month": [8, 7],
        "Year": [1991, 2024],
        "Destination": ["Stockholm", "New York"],
        "Source": ["Birmingham", "St petersburg"],
        "Dep_hours": [16, 0],
        "Dep_min": [33, 0],
        "Arrival_hours": [18, 3],
        "Arrival_min": [10, 30],
        "Duration_hours": [2, 12],
        "Duration_min": [3, 30],
        "Price": [440, 10000],
    }
    expected_result_data = {
        "Weekday": ["Tue", "Wed"],
        "TripID": ["Stockholm_Birmingham", "NewYork_Stpetersburg"],
        "Departure_hour_rounded": [17, 0],
        "Arrival_hour_rounded": [18, 3],
        "Total_duration_minutes": [123, 750],
        "Price": [440, 10000],
    }
    test_df = pd.DataFrame(data=test_data)

    res_df = feature_engineering.fn(df=test_df)
    res_df = feature_selection.fn(
        df=res_df,
        categorical_features=["Weekday", "TripID"],
        numerical_features=[
            "Departure_hour_rounded",
            "Arrival_hour_rounded",
            "Total_duration_minutes",
        ],
        target_column="Price",
    )

    with prefect_test_harness():
        assert deepdiff.DeepDiff(res_df.to_dict(), expected_result_data)
