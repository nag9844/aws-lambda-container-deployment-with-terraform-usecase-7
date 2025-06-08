#!/usr/bin/env python3
"""
Test script to verify Docker image builds correctly for Lambda
"""
import subprocess
import sys
import json
import os

def run_command(cmd, capture_output=True):
    """Run a shell command and return the result"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=capture_output, text=True, check=True)
        return result.stdout.strip() if capture_output else None
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {cmd}")
        print(f"Error: {e.stderr if capture_output else e}")
        return None

def test_docker_build():
    """Test building the Docker image locally"""
    print("🐳 Testing Docker build for Lambda compatibility...")
    print("=" * 60)
    
    # Change to src directory
    os.chdir('src')
    
    # Build the image
    print("1. Building Docker image...")
    image_name = "hello-world-lambda-test"
    build_cmd = f"docker build -t {image_name} --platform linux/amd64 ."
    
    if run_command(build_cmd, capture_output=False) is None:
        print("❌ Docker build failed")
        return False
    
    print("✅ Docker build successful")
    
    # Inspect the image
    print("\n2. Inspecting image...")
    inspect_cmd = f"docker inspect {image_name}"
    inspect_output = run_command(inspect_cmd)
    
    if inspect_output:
        try:
            inspect_data = json.loads(inspect_output)[0]
            architecture = inspect_data.get('Architecture', 'unknown')
            os_info = inspect_data.get('Os', 'unknown')
            
            print(f"   Architecture: {architecture}")
            print(f"   OS: {os_info}")
            
            if architecture != 'amd64':
                print(f"❌ Wrong architecture: {architecture} (should be amd64)")
                return False
            
            if os_info != 'linux':
                print(f"❌ Wrong OS: {os_info} (should be linux)")
                return False
                
        except json.JSONDecodeError:
            print("❌ Could not parse docker inspect output")
            return False
    
    # Test running the container locally
    print("\n3. Testing container execution...")
    
    # Create a test event file
    test_event = {
        "httpMethod": "GET",
        "path": "/",
        "headers": {"Accept": "application/json"},
        "queryStringParameters": None,
        "body": None
    }
    
    with open('/tmp/test_event.json', 'w') as f:
        json.dump(test_event, f)
    
    # Run the container with the test event
    run_cmd = f"docker run --rm -v /tmp/test_event.json:/tmp/test_event.json {image_name} python -c \"import json; from app import lambda_handler; class MockContext: aws_request_id='test'; function_name='test'; function_version='1'; memory_limit_in_mb=256; def get_remaining_time_in_millis(self): return 30000; event=json.load(open('/tmp/test_event.json')); result=lambda_handler(event, MockContext()); print('Response status:', result['statusCode']); print('Response type:', result['headers']['Content-Type'])\""
    
    container_output = run_command(run_cmd)
    if container_output:
        print(f"   Container output: {container_output}")
        if "Response status: 200" in container_output:
            print("✅ Container execution successful")
        else:
            print("❌ Container execution failed")
            return False
    else:
        print("❌ Could not run container test")
        return False
    
    # Clean up
    print("\n4. Cleaning up...")
    run_command(f"docker rmi {image_name}", capture_output=False)
    
    print("\n" + "=" * 60)
    print("🎉 All tests passed! Image is Lambda-compatible.")
    return True

if __name__ == "__main__":
    success = test_docker_build()
    sys.exit(0 if success else 1)