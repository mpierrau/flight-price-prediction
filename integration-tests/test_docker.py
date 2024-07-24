"""
Test for checking request results is fine
"""

import http

import requests


def test_valid_http_request() -> None:
    """
    Test for sending in data and checking result
    """
    flight_info = {
        "prediction_id": ["1", "2"],
        "airline": ["IndiGo", "IndiGo"],
        "source": ["Banglore", "Banglore"],
        "destination": ["New Delhi", "Kolkata"],
        "total_stops": [1, 2],
        "date": [24, 21],
        "month": [7, 2],
        "year": [2024, 1992],
        "dep_hours": [22, 4],
        "dep_min": [44, 4],
        "arrival_hours": [14, 0],
        "arrival_min": [40, 0],
        "duration_hours": [2, 5],
        "duration_min": [45, 50],
    }

    url = 'http://localhost:8080/predict'

    response = requests.post(url, json=flight_info, timeout=10)

    assert response.status_code == http.HTTPStatus.OK
    assert len(response.json()['predictions']) == 2
