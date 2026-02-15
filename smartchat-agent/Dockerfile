FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir . uvicorn[standard] fastapi

# Copy source code
COPY src/ src/
COPY server.py .

# Writable directory for SQLite job store
RUN mkdir -p /app/data
ENV SCHEDULER_DB_PATH=/app/data/jobs.sqlite

# Cloud Run sets PORT env var
ENV PORT=8080

CMD ["python", "server.py"]
