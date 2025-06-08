#!/usr/bin/env python3
"""
Local test script for Lambda function
"""
import json
from app import lambda_handler

# Mock Lambda context
class MockContext:
    def __init__(self):
        self.function_name = "hello-world-lambda-dev"
        self.function_version = "1.0.0"
        self.memory_limit_in_mb = 256
        self.aws_request_id = "test-request-id"
    
    def get_remaining_time_in_millis(self):
        return 30000

# Test event (API Gateway format)
test_event = {
    "httpMethod": "GET",
    "path": "/",
    "headers": {
        "Accept": "application/json"
    },
    "queryStringParameters": None,
    "body": None
}

if __name__ == "__main__":
    context = MockContext()
    response = lambda_handler(test_event, context)
    print("Response:")
    print(json.dumps(response, indent=2))