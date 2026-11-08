# Stage 1: Build & wheels
FROM python:3.11-slim AS builder

WORKDIR /app

RUN pip install --no-cache-dir --upgrade pip setuptools

COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Minimal runtime
FROM python:3.11-slim

WORKDIR /app

# Create a non-root service user
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY --from=builder /app/wheels /wheels
COPY requirements.txt .

# Install pre-built wheels and immediately clean up installer packages
RUN pip install --no-cache-dir /wheels/* && \
    rm -rf /wheels && \
    pip uninstall -y setuptools pip

COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 80

CMD ["gunicorn", "-b", "0.0.0.0:80", "app:app"]
