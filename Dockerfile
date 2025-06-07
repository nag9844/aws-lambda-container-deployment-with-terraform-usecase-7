# Use the official AWS Lambda Python runtime
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements and install dependencies
COPY app/requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

# Copy function code
COPY app/app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "app.lambda_handler" ]