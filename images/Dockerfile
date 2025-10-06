# Use Python 3.11 slim image as base
FROM python:3.11-slim-bookworm

# Set working directory
WORKDIR /app

# Install curl (non-interactive) and clean apt caches
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching (build context is repo root)
COPY images/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY images/app.py .

# Expose the port the app runs on
EXPOSE 5050

# Set environment variable for port
ENV PORT=5050

# Run the application
CMD ["python", "app.py"]
