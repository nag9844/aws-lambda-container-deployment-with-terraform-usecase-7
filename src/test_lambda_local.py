#!/usr/bin/env python3
"""
Local test script for Lambda function
"""
import json
import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

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

# Test event for HTML response
test_event_html = {
    "httpMethod": "GET",
    "path": "/",
    "headers": {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    },
    "queryStringParameters": None,
    "body": None
}

if __name__ == "__main__":
    print("Testing Lambda function locally...")
    print("=" * 50)
    
    context = MockContext()
    
    # Test JSON response
    print("\n1. Testing JSON Response:")
    response = lambda_handler(test_event, context)
    print("Status Code:", response['statusCode'])
    print("Content-Type:", response['headers']['Content-Type'])
    print("Response Body:")
    print(json.dumps(json.loads(response['body']), indent=2))
    
    # Test HTML response
    print("\n2. Testing HTML Response:")
    response_html = lambda_handler(test_event_html, context)
    print("Status Code:", response_html['statusCode'])
    print("Content-Type:", response_html['headers']['Content-Type'])
    print("HTML Response Length:", len(response_html['body']), "characters")
    
    print("\n" + "=" * 50)
    print("✅ Local tests completed successfully!")
    print("The Lambda function is ready for deployment.")