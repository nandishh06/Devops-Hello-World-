# Multi-stage build for security and efficiency
FROM python:3.12-slim as builder

# Create non-root user
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --user -r requirements.txt

# Copy application code
COPY hello.py /app/hello.py

# Production stage
FROM python:3.12-slim

# Install security updates and system dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Copy application and dependencies from builder stage
COPY --from=builder /app/hello.py /app/hello.py
COPY --from=builder /root/.local /home/appuser/.local

# Create logs directory
RUN mkdir -p /app/logs && \
    chown -R appuser:appuser /app

# Add .local to PATH for user-installed packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Set signal handling for graceful shutdown
STOPSIGNAL SIGTERM

# Expose port
EXPOSE 8080

# Run the application
CMD ["python", "hello.py"]
