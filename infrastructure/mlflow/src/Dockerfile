FROM python:3.11.9-slim

# Send logs immediately to the stream, they wont be part of the buffer
ENV PYTHONUNBUFFERED=True

RUN pip install poetry==1.8.3

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

COPY ./pyproject.toml ./pyproject.toml

RUN poetry install && rm -rf ${POETRY_CACHE_DIR}

COPY entrypoint.sh /app/entrypoint.sh
COPY mlflow_auth.py /app/mlflow_auth.py

ENTRYPOINT ["poetry", "run", "bash", "/app/entrypoint.sh"]

EXPOSE 8080
