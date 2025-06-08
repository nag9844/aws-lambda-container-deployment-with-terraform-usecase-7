# Use the official AWS Lambda Python runtime as base image
FROM public.ecr.aws/lambda/python:3.11

# Set working directory
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD ["app.lambda_handler"]
