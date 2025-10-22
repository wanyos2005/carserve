#backend/service_provider_service/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Install with timeout and retry settings for better reliability
RUN pip install --no-cache-dir --timeout=1000 --retries=5 -r requirements.txt

COPY app ./app
COPY alembic.ini .
COPY alembic ./alembic

ENV PYTHONUNBUFFERED=1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8003", "--reload"]
EXPOSE 8003
