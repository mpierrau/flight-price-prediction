"""
Unit tests for preprocessing code
"""

import pandas as pd
import deepdiff
from prefect.testing.utilities import prefect_test_harness

from training.feature_engineering import feature_selection, feature_engineering


def test_preprocess_data() -> None:
    """
    Test feature engineering and selection functions
    """
    test_data = {
        "airline": ["IndiGo", "IndiGo"],
        "total_stops": [2, 1],
        "date": [6, 17],
        "month": [8, 7],
        "year": [1991, 2024],
        "destination": ["Stockholm", "New York"],
        "source": ["Birmingham", "St petersburg"],
        "dep_hours": [16, 0],
        "dep_min": [33, 0],
        "arrival_hours": [18, 3],
        "arrival_min": [10, 30],
        "duration_hours": [2, 12],
        "duration_min": [3, 30],
        "price": [440, 10000],
    }
    expected_result_data = {
        "weekday": ["Tue", "Wed"],
        "tripid": ["Stockholm_Birmingham", "NewYork_Stpetersburg"],
        "departure_hour_rounded": [17, 0],
        "arrival_hour_rounded": [18, 3],
        "total_duration_minutes": [123, 750],
        "price": [440, 10000],
    }
    test_df = pd.DataFrame(data=test_data)

    res_df = feature_engineering(df=test_df)
    res_df = feature_selection(
        df=res_df,
    )

    with prefect_test_harness():
        assert deepdiff.DeepDiff(res_df.to_dict(), expected_result_data)
