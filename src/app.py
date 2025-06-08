import sys

def lambda_handler(event, context):
    """
    Simple AWS Lambda handler that returns plain text Hello World
    """
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/plain',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': 'Hello World!'
    }