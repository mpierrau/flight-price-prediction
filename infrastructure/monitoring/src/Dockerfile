FROM public.ecr.aws/lambda/python:3.11.2024.08.06.12

RUN pip install -U pip
RUN pip install poetry

COPY [ "pyproject.toml", "poetry.lock", "./"]

RUN poetry config virtualenvs.create false
RUN poetry lock --no-update
RUN poetry install

COPY [ "lambda_function.py", "create_report.py", "monitoring_svc.py", "create_new_data.py", "./"]

CMD [ "lambda_function.lambda_handler" ]
