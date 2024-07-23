"""
Data models
"""

from pydantic import BaseModel


class PredictionPostAPIModel(BaseModel):
    """
    Data models for prediction service input
    """

    prediction_id: list[str | int]
    airline: list[str]
    source: list[str]
    destination: list[str]
    total_stops: list[int]
    date: list[int]
    month: list[int]
    year: list[int]
    dep_hours: list[int]
    dep_min: list[int]
    arrival_hours: list[int]
    arrival_min: list[int]
    duration_hours: list[int]
    duration_min: list[int]
