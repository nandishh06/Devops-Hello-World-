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
        args = ["-c", <<EOF
import subprocess
import sys
import os

# Install required packages
print('Installing Flask and dependencies...')
subprocess.run([sys.executable, '-m', 'pip', 'install', 'flask', 'prometheus_client', 'psutil'], check=True)

# Create a simple Flask app
from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello, DevOps!',
        'timestamp': time.time(),
        'status': 'running'
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time()
    })

if __name__ == '__main__':
    print('Starting Flask app on port 8080...')
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF
]
        
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
