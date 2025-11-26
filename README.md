# DevOps Hello World - Secure & Production-Ready

Hi! I'm **Nandish Hiremath** and this is my enhanced DevOps intern project (November 2025). I've built a production-ready workflow with enterprise-grade security, monitoring, and best practices. This project demonstrates a complete DevOps pipeline with authentication, TLS/HTTPS, proper error handling, and comprehensive monitoring.

## Overview
- **Application:** Flask-based Python web service with health checks, metrics, and structured logging
- **Security:** Non-root containers, TLS/HTTPS encryption, authentication for all services
- **Monitoring:** Prometheus + Grafana + Loki stack with alerts and dashboards
- **Deployment:** Nomad with restart policies, rolling updates, and health checks
- **CI/CD:** GitHub Actions with automated testing and deployment

## Key Improvements
✅ **Security Best Practices**
- Non-root Docker containers
- TLS/HTTPS for all services
- Authentication and authorization
- Secure secret management

✅ **Production Readiness**
- Health checks and monitoring
- Restart policies and error handling
- Rolling updates and zero downtime
- Resource limits and constraints

✅ **Observability**
- Prometheus metrics
- Structured logging with Loki
- Grafana dashboards and alerts
- Distributed tracing support

## Project Structure
```
.
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── requirements.txt
├── .env.example
├── docker-compose.yml
├── README.md
├── hello.py
├── scripts/
│   ├── setup.sh
│   ├── generate-certs.sh
│   └── sysinfo.sh
├── nomad/
│   └── hello.nomad
└── monitoring/
    ├── loki-config.yaml
    ├── prometheus/
    │   ├── prometheus.yml
    │   ├── tls/
    │   │   └── web-config.yml
    │   └── rules/
    │       └── alerts.yml
    ├── grafana/
    │   └── provisioning/
    │       └── datasources/
    │           └── loki.yml
    ├── promtail-config.yml
    └── tls/
```

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Nomad
- OpenSSL
- Make (optional)

### Automated Setup
```bash
# Clone the repository
git clone https://github.com/nandishh06/Devops-Hello-World-.git
cd Devops-Hello-World-

# Run the setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### Manual Setup

1. **Generate TLS Certificates**
```bash
chmod +x scripts/generate-certs.sh
./scripts/generate-certs.sh
```

2. **Configure Environment**
```bash
cp .env.example .env
# Edit .env with your passwords and configuration
```

3. **Build and Deploy**
```bash
# Build Docker image
docker build -t hello-devops:latest .

# Start monitoring stack
docker-compose up -d

# Deploy to Nomad
nomad job run nomad/hello.nomad
```

## Service Endpoints

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | http://localhost:8080 | - |
| Health Check | http://localhost:8080/health | - |
| Metrics | http://localhost:8080/metrics | - |
| Grafana | https://localhost:3000 | admin/.env password |
| Prometheus | http://localhost:9090 | - |
| Loki | http://localhost:3100 | - |

## Security Features

### Authentication
- Grafana: Basic authentication with admin credentials
- Loki: Optional basic authentication
- Prometheus: Optional basic authentication
- Application: Environment-based configuration

### TLS/HTTPS
- Self-signed certificates for development
- Certificate generation script included
- HTTPS endpoints for Grafana
- TLS configuration for all services

### Container Security
- Non-root user (appuser:1001)
- Multi-stage Docker builds
- Minimal attack surface
- Resource limits and constraints

## Monitoring & Alerting

### Metrics
- Application metrics (request count, duration, errors)
- System metrics (CPU, memory, disk)
- Container metrics (if using cAdvisor)
- Custom business metrics

### Logging
- Structured JSON logging
- Centralized log aggregation with Loki
- Log-based alerts
- Log retention policies

### Alerts
- Application downtime
- High error rates
- Resource exhaustion
- Service health checks

## Deployment Strategies

### Rolling Updates
```bash
# Update with rolling deployment
nomad job run -update hello.nomad
```

### Canary Deployments
```bash
# Deploy with canary strategy
nomad job run -update-stagger=5m hello.nomad
```

### Blue-Green Deployments
```bash
# Deploy new version alongside old
nomad job run hello-v2.nomad
# Switch traffic when ready
```

## Troubleshooting

### Common Issues

1. **Certificate Warnings**
   - Trust the CA certificate: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain monitoring/tls/ca.crt` (macOS)
   - Or use `curl -k` for testing

2. **Permission Denied**
   - Ensure scripts are executable: `chmod +x scripts/*.sh`
   - Check Docker permissions: `sudo usermod -aG docker $USER`

3. **Port Conflicts**
   - Check port usage: `lsof -i :8080`
   - Update ports in .env file

### Health Checks
```bash
# Check application health
curl http://localhost:8080/health

# Check service status
docker-compose ps

# Check Nomad jobs
nomad job status
```

## Development

### Local Development
```bash
# Run in development mode
export APP_DEBUG=true
export LOG_LEVEL=debug
python hello.py
```

### Testing
```bash
# Run unit tests
python -m pytest tests/

# Run integration tests
python -m pytest tests/integration/

# Load testing
locust -f tests/load_test.py
```

### Code Quality
```bash
# Lint code
flake8 hello.py
black hello.py

# Security scan
bandit hello.py

# Dependency check
safety check
```

## Production Deployment

### Environment Variables
```bash
# Production configuration
export APP_ENV=production
export LOG_LEVEL=info
export APP_DEBUG=false
export GRAFANA_ADMIN_PASSWORD=your-secure-password
export LOKI_PASSWORD=your-secure-password
```

### Resource Limits
```bash
# Set resource constraints
docker-compose up -d --scale prometheus=1 --scale grafana=1
```

### Backup & Recovery
```bash
# Backup data
docker-compose exec prometheus tar czf /backup/prometheus-$(date +%Y%m%d).tar.gz /prometheus
docker-compose exec grafana tar czf /backup/grafana-$(date +%Y%m%d).tar.gz /var/lib/grafana
```

## Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License
MIT License - see LICENSE file for details

## Acknowledgments
- HashiCorp for Nomad
- Grafana Labs for Grafana and Loki
- Prometheus for metrics
- Docker for containerization

---

**Note:** This project is for educational purposes. In production, use proper certificate authorities, secret management systems (Vault), and external monitoring solutions.

## Step 1: Git & GitHub
- Initialize and push:
```
git init
git add .
git commit -m "Initial commit: DevOps intern final"
# Create a GitHub repo named devops-intern-final, then:
git branch -M main
git remote add origin git@github.com:<your-username>/devops-intern-final.git
git push -u origin main
```

## Step 2: Linux & Shell Scripting
- Run the system info script:
```
chmod +x scripts/sysinfo.sh
./scripts/sysinfo.sh
```
It prints current user, date, and disk usage.

## Step 3: Docker
- Build and run the app container:
```
docker build -t hello-devops:latest .
docker run --rm hello-devops:latest
```

## Step 4: CI/CD with GitHub Actions
The workflow in `.github/workflows/ci.yml` runs on every push/PR:
- Checks out code
- Sets up Python 3.12
- Runs `python hello.py`

You should see the logs in GitHub Actions with the message output.

## Step 5: Nomad Deployment
- Make sure you have a Nomad agent running (dev mode is fine):
```
nomad agent -dev
```
- Run the job:
```
nomad job run nomad/hello.nomad
```
- Check status:
```
nomad job status hello-devops
```
The job uses the local Docker image tag `hello-devops:latest`.

## Step 6: Monitoring with Grafana Loki
- Quickstart using Docker (see `monitoring/loki_setup.txt`):
```
docker run -d --name loki -p 3100:3100 grafana/loki:2.9.8

docker run -d --name promtail \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v $(pwd)/monitoring/promtail-config.yml:/etc/promtail/config.yml:ro \
  -p 9080:9080 \
  grafana/promtail:2.9.8 \
  -config.file=/etc/promtail/config.yml

curl -s "http://localhost:3100/ready"
```
- Optional: Run Grafana and add Loki as a data source at `http://localhost:3100`.

## What I Learned
- I started by creating the app and Dockerfile, which made the CI setup straightforward.
- This helped me understand how container images move from local builds to orchestration (Nomad).
- Setting up Promtail taught me how logs flow from containers into Loki.
- This was my first time trying Nomad, and it gave me a good idea of container orchestration.

## Optional Extension
- Try pushing the image to a registry (e.g., GHCR or Docker Hub) and updating Nomad to pull it.
- Add a simple dashboard in Grafana.
- Explore adding MLflow or deploying to a small VM.

## Final Thoughts
This repo captures a small, end-to-end DevOps loop I can build on. Feedback welcome!
