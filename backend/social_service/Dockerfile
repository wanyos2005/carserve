FROM python:3.11-slim

WORKDIR /app

# Install curl for health checks and build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Install with timeout and retry settings for better reliability
RUN pip install --no-cache-dir --timeout=1000 --retries=5 -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8008", "--reload"]
