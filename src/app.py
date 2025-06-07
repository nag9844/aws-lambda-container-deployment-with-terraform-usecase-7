import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda handler function for Hello World application
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        dict: HTTP response
    """
    
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Extract request information
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    query_params = event.get('queryStringParameters') or {}
    
    # Create response body
    response_body = {
        "message": "Hello World from AWS Lambda Container!",
        "method": http_method,
        "path": path,
        "timestamp": context.aws_request_id,
        "version": "1.0.0",
        "environment": {
            "function_name": context.function_name,
            "function_version": context.function_version,
            "memory_limit": context.memory_limit_in_mb,
            "remaining_time": context.get_remaining_time_in_millis()
        }
    }
    
    # Add query parameters if present
    if query_params:
        response_body["query_parameters"] = query_params
    
    # Create HTML response for browser viewing
    if event.get('headers', {}).get('Accept', '').find('text/html') >= 0:
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Hello World Lambda</title>
            <style>
                body {{ 
                    font-family: Arial, sans-serif; 
                    margin: 40px; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }}
                .container {{ 
                    max-width: 800px; 
                    margin: 0 auto; 
                    background: rgba(255,255,255,0.1);
                    padding: 30px;
                    border-radius: 10px;
                    backdrop-filter: blur(10px);
                }}
                .header {{ font-size: 2.5em; margin-bottom: 20px; }}
                .info {{ 
                    background: rgba(255,255,255,0.1); 
                    padding: 15px; 
                    border-radius: 5px; 
                    margin: 10px 0;
                }}
                .highlight {{ color: #ffd700; font-weight: bold; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1 class="header">🚀 Hello World from AWS Lambda!</h1>
                <div class="info">
                    <p><span class="highlight">Function:</span> {context.function_name}</p>
                    <p><span class="highlight">Version:</span> {context.function_version}</p>
                    <p><span class="highlight">Memory:</span> {context.memory_limit_in_mb} MB</p>
                    <p><span class="highlight">Request ID:</span> {context.aws_request_id}</p>
                    <p><span class="highlight">Method:</span> {http_method}</p>
                    <p><span class="highlight">Path:</span> {path}</p>
                </div>
                <p>This containerized Lambda function is deployed using:</p>
                <ul>
                    <li>✅ Docker Container</li>
                    <li>✅ Terraform Infrastructure</li>
                    <li>✅ GitHub Actions CI/CD</li>
                    <li>✅ AWS ECR Registry</li>
                    <li>✅ API Gateway Integration</li>
                </ul>
            </div>
        </body>
        </html>
        """
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'text/html',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': html_content
        }
    
    # JSON response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(response_body, indent=2)
    }