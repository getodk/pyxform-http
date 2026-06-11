FROM python:3.12-alpine AS builder
COPY --from=ghcr.io/astral-sh/uv:0.11.9 /uv /uvx /bin/

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

COPY pyproject.toml \
     uv.lock \
   .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync \
        --frozen \
        --no-dev

#---
FROM python:3.12-alpine

RUN apk --update add openjdk8-jre-base

COPY --from=builder /app/.venv /app/.venv

WORKDIR /app
COPY ./app .

ENV PATH="/app/.venv/bin:$PATH"
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "5", "--timeout", "600", "--max-requests", "1", "--max-requests-jitter", "3", "main:app()"]
