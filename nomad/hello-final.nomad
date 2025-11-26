job "hello-devops" {
  datacenters = ["dc1"]
  type = "batch"

  group "hello" {
    count = 1

    network {
      port "http" {
        static = 8080
        to = 8080
      }
    }

    task "hello-container" {
      driver = "docker"

      config {
        image = "python:3.12-slim"
        command = "python"
        args = ["-c", <<EOF
import subprocess
import sys
import os
import time

# Install required packages
print('Installing Flask and dependencies...')
subprocess.run([sys.executable, '-m', 'pip', 'install', 'flask', 'prometheus_client', 'psutil'], check=True)

# Create a Flask app with metrics
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import psutil

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('hello_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('hello_request_duration_seconds', 'Request duration')
APP_START_TIME = time.time()

@app.route('/')
def hello():
    start_time = time.time()
    try:
        response = {
            'message': 'Hello, DevOps!',
            'timestamp': time.time(),
            'status': 'running',
            'uptime': time.time() - APP_START_TIME
        }
        REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
        return jsonify(response)
    finally:
        REQUEST_DURATION.observe(time.time() - start_time)

@app.route('/health')
def health():
    start_time = time.time()
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        
        health_data = {
            'status': 'healthy',
            'timestamp': time.time(),
            'uptime': time.time() - APP_START_TIME,
            'system': {
                'cpu_percent': cpu_percent,
                'memory_percent': memory.percent
            }
        }
        
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status='200').inc()
        return jsonify(health_data)
    finally:
        REQUEST_DURATION.observe(time.time() - start_time)

@app.route('/metrics')
def metrics():
    REQUEST_COUNT.labels(method='GET', endpoint='/metrics', status='200').inc()
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/info')
def info():
    start_time = time.time()
    try:
        info_data = {
            'application': 'DevOps Hello World',
            'version': '1.0.0',
            'environment': os.getenv('APP_ENV', 'production'),
            'timestamp': time.time(),
            'endpoints': ['/', '/health', '/metrics', '/info']
        }
        REQUEST_COUNT.labels(method='GET', endpoint='/info', status='200').inc()
        return jsonify(info_data)
    finally:
        REQUEST_DURATION.observe(time.time() - start_time)

if __name__ == '__main__':
    print('Starting Flask app on port 8080 with metrics...')
    print('Available endpoints:')
    print('  /        - Main endpoint')
    print('  /health  - Health check')
    print('  /metrics - Prometheus metrics')
    print('  /info    - Application info')
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF
]
        
        # Port mapping for host access
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
