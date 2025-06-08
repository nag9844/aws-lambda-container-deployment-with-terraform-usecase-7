# Use the official AWS Lambda Python runtime as base image
FROM public.ecr.aws/lambda/python:3.12

# Set working directory to Lambda task root
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy requirements file first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies (if any)
RUN if [ -s requirements.txt ]; then \
        pip install --no-cache-dir --upgrade pip && \
        pip install --no-cache-dir -r requirements.txt; \
    else \
        echo "No requirements to install"; \
    fi

# Copy application code
COPY app.py .

# Set the CMD to your handler (this is the entry point)
CMD ["app.lambda_handler"]

# Add metadata labels
LABEL maintainer="DevOps Team"
LABEL version="2.2.0"
LABEL description="Fixed Hello World Lambda Container"
LABEL updated="2025-06-08"
LABEL python.version="3.12"
LABEL architecture="amd64"

# Health check for local testing (optional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import app; print('Container is healthy')" || exit 1