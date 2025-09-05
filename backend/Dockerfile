# syntax=docker/dockerfile:1.7

########################
# Base image
########################
FROM python:3.13-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Optional: set a consistent locale
ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

WORKDIR /app

# System deps (add build tools only if you compile wheels)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -u 10001 -m appuser

########################
# Runtime image (Production)
########################
FROM base AS prod

# Install runtime requirements
COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

# Copy source
COPY backend /app/backend

# Switch to non-root
USER appuser

# Expose FastAPI default port (change if you use another)
EXPOSE 8000

# IMPORTANT: update "backend.main:app" to where your FastAPI app object lives.
# Examples:
#  - backend.main:app
#  - backend.api.server:app
#  - backend.app:app
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]

########################
# Dev image (optional)
########################
FROM base AS dev

# Install runtime + dev tooling
COPY requirements.txt requirements-dev.txt /app/
RUN pip install -r /app/requirements-dev.txt

# Copy source
COPY backend /app/backend

USER appuser
EXPOSE 8000
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
