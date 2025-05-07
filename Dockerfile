## Builder

FROM python:3.12-slim AS builder
ENV POETRY_VERSION=2.1.3 \
  POETRY_HOME="/opt/poetry" \
  POETRY_NO_INTERACTION=1 \
  POETRY_VIRTUALENVS_IN_PROJECT=1 \
  POETRY_CACHE_DIR="/var/cache/pypoetry" \
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && curl -sSL https://install.python-poetry.org | python3 - \
  && rm -rf /var/lib/apt/lists/*

ENV PATH="$POETRY_HOME/bin:$PATH"

WORKDIR /app

COPY pyproject.toml poetry.lock ./

RUN --mount=type=cache,target=${POETRY_CACHE_DIR} \
  poetry install --no-root --only main
RUN --mount=type=cache,target=${POETRY_CACHE_DIR} \
  poetry install --no-root --only dev


## Runtime
FROM python:3.12-slim AS runtime
ENV POETRY_VIRTUALENVS_IN_PROJECT=1 \
  VIRTUAL_ENV="/code/.venv" \
  PATH="/code/.venv/bin:$PATH" \
  PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1

WORKDIR /code
COPY --from=builder /app/.venv /code/.venv
COPY . .

EXPOSE 8000
ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
