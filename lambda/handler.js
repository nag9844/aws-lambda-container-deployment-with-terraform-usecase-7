const fs = require('fs');
const path = require('path');

exports.lambdaHandler = async (event, context) => {
    try {
        // Read the built HTML file
        const htmlPath = path.join(__dirname, 'dist', 'index.html');
        let html = fs.readFileSync(htmlPath, 'utf8');
        
        // Handle different request paths
        const requestPath = event.requestContext?.http?.path || event.path || '/';
        
        // For API Gateway requests, return HTML response
        if (requestPath.includes('/api/') || event.httpMethod) {
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'text/html',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                },
                body: html
            };
        }
        
        // For direct Lambda invocation
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Hello World from AWS Lambda Container!',
                timestamp: new Date().toISOString(),
                requestId: context.awsRequestId,
                environment: process.env.ENVIRONMENT || 'development'
            })
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Internal Server Error',
                message: error.message
            })
        };
    }
};