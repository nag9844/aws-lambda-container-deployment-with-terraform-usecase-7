# Use the official AWS Lambda Python runtime as base image
FROM public.ecr.aws/lambda/python:3.12

# Set working directory
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Set the CMD to your handler
CMD ["app.lambda_handler"]

# Add labels for better container management
LABEL maintainer="DevOps Team"
LABEL version="2.1.0"
LABEL description="Updated Hello World Lambda Container"
LABEL updated="2025-06-08"

# Add health check (optional, for local testing)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import app; print('Container is healthy')" || exit 1