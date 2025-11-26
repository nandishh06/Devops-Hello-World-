job "hello-devops" {
  datacenters = ["dc1"]
  type = "batch"

  group "hello" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    task "hello-container" {
      driver = "docker"

      config {
        image = "python:3.12-slim"
        command = "python"
        args = ["hello.py"]
        
        # Port mapping
        ports = ["http"]
        
        # Logging configuration
        logging {
          type = "json-file"
          config {
            max-size = "10m"
            max-file = "3"
          }
        }
      }

      # Template to copy hello.py into container
      template {
        destination = "local/hello.py"
        data = <<EOH
#!/usr/bin/env python3
"""
DevOps Hello World Application
A simple Flask application with health checks, logging, and metrics
"""

import os
import sys
import logging
import time
from datetime import datetime
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import psutil

# Configure logging
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/app/logs/app.log', mode='a')
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('hello_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('hello_request_duration_seconds', 'Request duration')
APP_START_TIME = time.time()

@app.route('/')
@REQUEST_DURATION.time()
def hello():
    """Main endpoint"""
    start_time = time.time()
    try:
        message = os.getenv('HELLO_MESSAGE', 'Hello, DevOps!')
        response = {
            'message': message,
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0',
            'environment': os.getenv('APP_ENV', 'production')
        }
        logger.info(f"Hello endpoint accessed: {message}")
        REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
        return jsonify(response)
    except Exception as e:
        logger.error(f"Error in hello endpoint: {str(e)}")
        REQUEST_COUNT.labels(method='GET', endpoint='/', status='500').inc()
        return jsonify({'error': 'Internal server error'}), 500
    finally:
        duration = time.time() - start_time
        logger.info(f"Request processed in {duration:.3f} seconds")

@app.route('/health')
@REQUEST_DURATION.time()
def health_check():
    """Health check endpoint"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        status = 'healthy'
        if cpu_percent > 90:
            status = 'degraded'
        if memory.percent > 90:
            status = 'degraded'
        if disk.percent > 90:
            status = 'degraded'
        
        health_data = {
            'status': status,
            'timestamp': datetime.utcnow().isoformat(),
            'uptime': time.time() - APP_START_TIME,
            'checks': {
                'cpu': {'status': 'pass' if cpu_percent < 90 else 'fail', 'value': f"{cpu_percent}%", 'threshold': '90%'},
                'memory': {'status': 'pass' if memory.percent < 90 else 'fail', 'value': f"{memory.percent}%", 'threshold': '90%'},
                'disk': {'status': 'pass' if disk.percent < 90 else 'fail', 'value': f"{disk.percent}%", 'threshold': '90%'}
            }
        }
        
        logger.info(f"Health check completed: {status}")
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status='200').inc()
        
        if status == 'healthy':
            return jsonify(health_data), 200
        else:
            return jsonify(health_data), 503
            
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status='500').inc()
        return jsonify({'status': 'unhealthy', 'error': str(e), 'timestamp': datetime.utcnow().isoformat()}), 500

@app.route('/metrics')
@REQUEST_DURATION.time()
def metrics():
    """Prometheus metrics endpoint"""
    try:
        logger.debug("Metrics endpoint accessed")
        REQUEST_COUNT.labels(method='GET', endpoint='/metrics', status='200').inc()
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
    except Exception as e:
        logger.error(f"Error generating metrics: {str(e)}")
        REQUEST_COUNT.labels(method='GET', endpoint='/metrics', status='500').inc()
        return jsonify({'error': 'Failed to generate metrics'}), 500

@app.route('/info')
@REQUEST_DURATION.time()
def info():
    """Application information endpoint"""
    try:
        info_data = {
            'application': 'DevOps Hello World',
            'version': '1.0.0',
            'python_version': sys.version,
            'environment': os.getenv('APP_ENV', 'production'),
            'timestamp': datetime.utcnow().isoformat(),
            'system': {
                'platform': sys.platform,
                'hostname': os.uname().nodename,
                'pid': os.getpid()
            }
        }
        logger.info("Info endpoint accessed")
        REQUEST_COUNT.labels(method='GET', endpoint='/info', status='200').inc()
        return jsonify(info_data)
    except Exception as e:
        logger.error(f"Error in info endpoint: {str(e)}")
        REQUEST_COUNT.labels(method='GET', endpoint='/info', status='500').inc()
        return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path, status='404').inc()
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path, status='500').inc()
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

def create_app():
    """Application factory"""
    return app

if __name__ == '__main__':
    logger.info("Starting DevOps Hello World Application")
    
    # Create logs directory if it doesn't exist
    os.makedirs('/app/logs', exist_ok=True)
    
    # Get configuration from environment
    host = os.getenv('APP_HOST', '0.0.0.0')
    port = int(os.getenv('APP_PORT', 8080))
    debug = os.getenv('APP_DEBUG', 'false').lower() == 'true'
    
    logger.info(f"Starting server on {host}:{port}")
    app.run(host=host, port=port, debug=debug)
else:
    # Simple message for direct execution (backward compatibility)
    print("Hello, DevOps!")
EOH
      }

      # Environment variables
      env = {
        APP_PORT = "8080"
        APP_ENV = "production"
        LOG_LEVEL = "info"
      }
      
      # Resource constraints
      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
        }
      }
      
      # Restart policy
      restart {
        attempts = 3
        delay    = "10s"
        interval = "30s"
        mode     = "on-failure"
      }
    }
  }
}
