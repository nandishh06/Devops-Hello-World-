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
        image = "hello-devops:latest"
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
