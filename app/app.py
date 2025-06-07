import json
import os
from datetime import datetime

def lambda_handler(event, context):
    """
    AWS Lambda handler function
    """
    # Get environment variables
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    project_name = os.environ.get('PROJECT_NAME', 'hello-world-lambda')
    
    # Create response body
    response_body = {
        'message': 'Hello World from AWS Lambda Container!',
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'environment': environment,
        'project': project_name,
        'version': '1.0.0',
        'request_id': context.aws_request_id if context else 'local',
        'path': event.get('path', '/') if event else '/',
        'method': event.get('httpMethod', 'GET') if event else 'GET'
    }
    
    # Create HTML response for web display
    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Hello World - AWS Lambda</title>
        <style>
            body {{
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                margin: 0;
                padding: 0;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }}
            .container {{
                text-align: center;
                background: rgba(255, 255, 255, 0.1);
                padding: 2rem;
                border-radius: 15px;
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                max-width: 600px;
                margin: 2rem;
            }}
            h1 {{
                font-size: 3rem;
                margin-bottom: 1rem;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
            }}
            .subtitle {{
                font-size: 1.2rem;
                margin-bottom: 2rem;
                opacity: 0.9;
            }}
            .info-grid {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1rem;
                margin-top: 2rem;
            }}
            .info-card {{
                background: rgba(255, 255, 255, 0.15);
                padding: 1rem;
                border-radius: 10px;
                border: 1px solid rgba(255, 255, 255, 0.2);
            }}
            .info-label {{
                font-weight: bold;
                font-size: 0.9rem;
                opacity: 0.8;
                margin-bottom: 0.5rem;
            }}
            .info-value {{
                font-size: 1rem;
                word-break: break-all;
            }}
            .success-badge {{
                display: inline-block;
                background: #4CAF50;
                color: white;
                padding: 0.5rem 1rem;
                border-radius: 25px;
                font-size: 0.9rem;
                margin-top: 1rem;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1> Hello World!</h1>
            <p class="subtitle">Successfully deployed with AWS Lambda + Container + Terraform</p>
            <div class="success-badge"> Deployment Successful</div>
            
            <div class="info-grid">
                <div class="info-card">
                    <div class="info-label">Environment</div>
                    <div class="info-value">{environment.upper()}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Project</div>
                    <div class="info-value">{project_name}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Timestamp</div>
                    <div class="info-value">{response_body['timestamp']}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Request ID</div>
                    <div class="info-value">{response_body['request_id']}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Path</div>
                    <div class="info-value">{response_body['path']}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Method</div>
                    <div class="info-value">{response_body['method']}</div>
                </div>
            </div>
        </div>
    </body>
    </html>
    """
    
    # Return response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': html_content
    }

if __name__ == "__main__":
    # For local testing
    print("Testing Lambda function locally...")
    result = lambda_handler({}, None)
    print(json.dumps(result, indent=2))