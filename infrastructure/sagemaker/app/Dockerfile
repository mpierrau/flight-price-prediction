FROM python:3.11.9-slim

WORKDIR /opt/app

RUN apt-get -y update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev \
    libudev-dev \
    build-essential \
    ca-certificates \
    nginx && \
    rm -fr /var/lib/apt/lists/*

RUN pip install -U pip
RUN pip install poetry

ENV PATH="/opt/app:${PATH}"
ENV PYTHONPATH=.

COPY [ "pyproject.toml", "poetry.lock", "nginx.conf", "./" ]

RUN poetry config virtualenvs.create false
RUN poetry lock --no-update
RUN poetry install

COPY ./src .

EXPOSE 8080

RUN chmod +x serve
ENTRYPOINT ["serve"]
