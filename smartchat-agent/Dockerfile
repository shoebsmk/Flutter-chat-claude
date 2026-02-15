FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir . uvicorn[standard] fastapi

# Copy source code
COPY src/ src/
COPY server.py .

# Cloud Run sets PORT env var
ENV PORT=8080

CMD ["python", "server.py"]
