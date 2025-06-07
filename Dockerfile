# Use the official AWS Lambda base image for Python
FROM public.ecr.aws/lambda/python:3.11

# Copy function code
COPY src/lambda/lambda_function.py ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD [ "lambda_function.handler" ]