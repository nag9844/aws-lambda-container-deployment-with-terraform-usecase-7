# Use the official AWS Lambda Python runtime as base image
FROM public.ecr.aws/lambda/python:3.11

# Set working directory
WORKDIR /var/task

# Copy requirements if you have any (create empty for now)
# COPY requirements.txt .
# RUN pip install -r requirements.txt

# Copy application code
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD ["app.lambda_handler"]

# Add labels for better container management
LABEL maintainer="DevOps Team"
LABEL version="1.0.0"
LABEL description="Hello World Lambda Container"

# Add health check (optional, for local testing)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import app; print('Container is healthy')" || exit 1