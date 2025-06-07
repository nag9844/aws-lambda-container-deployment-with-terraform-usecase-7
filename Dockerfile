# Multi-stage build for AWS Lambda
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage optimized for AWS Lambda
FROM public.ecr.aws/lambda/nodejs:18

# Copy built application
COPY --from=builder /app/dist ${LAMBDA_TASK_ROOT}/dist
COPY --from=builder /app/node_modules ${LAMBDA_TASK_ROOT}/node_modules
COPY --from=builder /app/package.json ${LAMBDA_TASK_ROOT}/

# Copy lambda handler
COPY lambda/handler.js ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD [ "handler.lambdaHandler" ]