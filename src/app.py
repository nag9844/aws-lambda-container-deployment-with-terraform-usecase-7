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
    
    # Simple Hello World response with updated message
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/plain',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': 'Hello World! This is a simple AWS Lambda function running in a container.'
    }