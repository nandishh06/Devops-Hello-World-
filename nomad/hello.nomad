job "hello-devops" {
  datacenters = ["dc1"]
  type = "batch"

  group "hello" {
    count = 1

    task "hello-container" {
      driver = "docker"

      config {
        image = "python:3.12-slim"
        command = "python"
        args = ["-c", "print('Hello from Python in Nomad!')"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}