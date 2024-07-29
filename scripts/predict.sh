curl -X POST http://16.171.153.144:8080/predict -d '{
    "prediction_id":["1","2"],
    "airline":["IndiGo","IndiGo"],
    "source":["Banglore","Banglore"],
    "destination":["New Delhi","Kolkata"],
    "total_stops":[1,1],
    "date":[24, 21],
    "month":[7, 2],
    "year":[2024, 1992],
    "dep_hours":[22, 4],
    "dep_min":[44, 4],
    "arrival_hours":[14, 0],
    "arrival_min":[40, 0],
    "duration_hours":[2, 5],
    "duration_min":[45, 50]
    }' | jq
