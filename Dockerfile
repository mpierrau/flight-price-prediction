FROM --platform=linux/amd64 python:3.11.9-slim

WORKDIR /app

RUN pip install -U pip & pip install poetry

COPY [ "pyproject.toml", "poetry.lock", "./" ]

RUN poetry config virtualenvs.create false
RUN poetry lock --no-update & poetry install --without dev

COPY ./app .

EXPOSE 8080

CMD ["python", "main.py"]
