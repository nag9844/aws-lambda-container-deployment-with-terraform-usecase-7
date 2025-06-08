#!/usr/bin/env python3
"""
Local testing script for Lambda function
This script simulates the Lambda runtime environment for local testing
"""

import json
import sys
import os

# Add current directory to path to import app module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import app
except ImportError as e:
    print(f"❌ Failed to import app module: {e}")
    sys.exit(1)

class MockLambdaContext:
    """Mock Lambda context for local testing"""
    
    def __init__(self):
        self.function_name = "hello-world-lambda-dev"
        self.function_version = "$LATEST"
        self.invoked_function_arn = "arn:aws:lambda:ap-south-1:123456789012:function:hello-world-lambda-dev"
        self.memory_limit_in_mb = "256"
        self.remaining_time_in_millis = 30000
        self.log_group_name = "/aws/lambda/hello-world-lambda-dev"
        self.log_stream_name = "2023/01/01/[$LATEST]abcdef123456"
        self.aws_request_id = "test-request-id-12345"
        self.identity = None
        self.client_context = None
    
    def get_remaining_time_in_millis(self):
        return self.remaining_time_in_millis

def test_lambda_handler():
    """Test the Lambda handler with various event types"""
    
    print("🧪 Testing Lambda handler locally...")
    
    # Test cases
    test_cases = [
        {
            "name": "API Gateway GET request",
            "event": {
                "httpMethod": "GET",
                "path": "/",
                "headers": {
                    "Accept": "application/json"
                },
                "queryStringParameters": None
            }
        },
        {
            "name": "API Gateway GET request with query params",
            "event": {
                "httpMethod": "GET", 
                "path": "/test",
                "headers": {
                    "Accept": "application/json"
                },
                "queryStringParameters": {
                    "name": "test",
                    "version": "1.0"
                }
            }
        },
        {
            "name": "Browser request (HTML response)",
            "event": {
                "httpMethod": "GET",
                "path": "/",
                "headers": {
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
                },
                "queryStringParameters": None
            }
        }
    ]
    
    context = MockLambdaContext()
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n🔍 Test {i}: {test_case['name']}")
        
        try:
            # Call the Lambda handler
            response = app.lambda_handler(test_case['event'], context)
            
            # Validate response structure
            if not isinstance(response, dict):
                print(f"❌ Response is not a dictionary: {type(response)}")
                continue
                
            if 'statusCode' not in response:
                print(f"❌ Response missing statusCode: {response}")
                continue
                
            if 'headers' not in response:
                print(f"❌ Response missing headers: {response}")
                continue
                
            if 'body' not in response:
                print(f"❌ Response missing body: {response}")
                continue
            
            # Check status code
            status_code = response['statusCode']
            if status_code != 200:
                print(f"❌ Unexpected status code: {status_code}")
                continue
            
            # Check content type
            content_type = response['headers'].get('Content-Type', '')
            print(f"📄 Content-Type: {content_type}")
            
            # Preview response body
            body = response['body']
            if content_type == 'application/json':
                try:
                    parsed_body = json.loads(body)
                    print(f"📊 JSON Response keys: {list(parsed_body.keys())}")
                    print(f"📝 Message: {parsed_body.get('message', 'N/A')}")
                except json.JSONDecodeError:
                    print(f"❌ Invalid JSON in response body")
                    continue
            else:
                # HTML response
                body_preview = body[:200] + "..." if len(body) > 200 else body
                print(f"📄 HTML Response preview: {body_preview}")
            
            print(f"✅ Test {i} passed!")
            
        except Exception as e:
            print(f"❌ Test {i} failed with exception: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\n🎉 Local testing completed!")

if __name__ == "__main__":
    test_lambda_handler()