# flight-price-prediction
My Final Project for the DataTalks MLOPS Zoomcamp 2024

## Preparations
### Data
1. Download `flight_dataset.csv` from [Kaggle Flight Price Prediction Dataset](https://www.kaggle.com/datasets/shubhambathwal/flight-price-prediction/data).
2. Place it in the `data/` directory

## Installation
1. Install [`poetry`](https://python-poetry.org/docs/)
2. Navigate to the folder with `pyproject.toml` and install dependencies: `poetry install`

### Prepare `Prefect`
I didn't like Mage AI so I'm using Prefect.

1. [Create](https://docs.prefect.io/2.14.2/getting-started/quickstart/#step-2-connect-to-prefects-api) a "forever free" account on prefect<>.
2. Login to prefect using the cli command `prefect cloud login`.

### Prepare `MLFlow``MLFLOW_URI`
...

## Preprocessing
1. Start a virtual environment shell using `poetry shell`
2. Run the preprocessing by activating the poetry shell and running `python preprocessing/preprocess_data.py data/flight_dataset.csv`.

## Training
1. Prepare some environment variables:
    - `EXPERIMENT_NAME` annd `MLFLOW_URI` for MLFlow tracking
1. Run training runs for various models to find the best fit:
```bash
python training/optimization.py data/{training_data}.parquet data/{validation_data}.parquet --model-name XGBRegressor --num-trials 50 --loss-key rmse --target-column Price --seed 123456
```
