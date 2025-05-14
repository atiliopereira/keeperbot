# syntax=docker/dockerfile:1.4
###########
# Builder #
###########
FROM python:3.12-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends \ 
  curl build-essential \
  && rm -rf /var/lib/apt/lists/*


RUN pip install --upgrade pip \
  && pip install "poetry==2.1.3"

RUN poetry config virtualenvs.create false

WORKDIR /app
COPY pyproject.toml poetry.lock ./

RUN poetry install --no-root --only main --no-interaction --no-ansi && \
  poetry install --no-root --only dev

###########
# Runtime #
###########
FROM python:3.12-slim AS runtime

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

WORKDIR /code
COPY . .

EXPOSE 8000
ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
