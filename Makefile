# DevOps Project Makefile
# Provides convenient commands for managing the DevOps stack

.PHONY: help setup build start stop restart clean status logs test deploy health

# Default target
help: ## Show this help message
	@echo "DevOps Project Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup commands
setup: ## Setup the entire DevOps stack
	@echo "Setting up DevOps stack..."
	@chmod +x scripts/setup.sh
	@scripts/setup.sh setup

setup-dev: ## Setup for development environment
	@echo "Setting up development environment..."
	@cp .env.example .env
	@chmod +x scripts/generate-certs.sh
	@scripts/generate-certs.sh
	@docker build -t hello-devops:latest .

# Build commands
build: ## Build Docker image
	@echo "Building Docker image..."
	@docker build -t hello-devops:latest .

build-no-cache: ## Build Docker image without cache
	@echo "Building Docker image (no cache)..."
	@docker build --no-cache -t hello-devops:latest .

# Service management
start: ## Start all services
	@echo "Starting services..."
	@docker-compose up -d

stop: ## Stop all services
	@echo "Stopping services..."
	@docker-compose down

restart: ## Restart all services
	@echo "Restarting services..."
	@docker-compose restart

clean: ## Clean up containers and images
	@echo "Cleaning up..."
	@docker-compose down -v
	@docker system prune -f
	@docker volume prune -f

# Status and monitoring
status: ## Show service status
	@echo "Service Status:"
	@docker-compose ps
	@echo ""
	@echo "Nomad Jobs:"
	@nomad job status 2>/dev/null || echo "Nomad not running"

logs: ## Show logs from all services
	@docker-compose logs -f

logs-app: ## Show application logs
	@docker-compose logs -f hello-devops

logs-loki: ## Show Loki logs
	@docker-compose logs -f loki

logs-promtail: ## Show Promtail logs
	@docker-compose logs -f promtail

logs-grafana: ## Show Grafana logs
	@docker-compose logs -f grafana

logs-prometheus: ## Show Prometheus logs
	@docker-compose logs -f prometheus

# Health checks
health: ## Check health of all services
	@echo "Checking service health..."
	@echo "Application:"
	@curl -s http://localhost:8080/health | jq '.' || echo "Application not responding"
	@echo ""
	@echo "Grafana:"
	@curl -s http://localhost:3000/api/health | jq '.' || echo "Grafana not responding"
	@echo ""
	@echo "Prometheus:"
	@curl -s http://localhost:9090/-/healthy | jq '.' || echo "Prometheus not responding"
	@echo ""
	@echo "Loki:"
	@curl -s http://localhost:3100/ready | jq '.' || echo "Loki not responding"

# Nomad commands
deploy: ## Deploy application to Nomad
	@echo "Deploying to Nomad..."
	@nomad job run nomad/hello.nomad

undeploy: ## Stop and purge Nomad job
	@echo "Undeploying from Nomad..."
	@nomad job stop -purge hello-devops

nomad-status: ## Show Nomad job status
	@nomad job status hello-devops

nomad-logs: ## Show Nomad job logs
	@echo "Getting allocation ID..."
	@ALLOC_ID=$$(nomad job allocs -t '{{with index . 0}}{{.ID}}{{end}}' hello-devops 2>/dev/null); \
	if [ -n "$$ALLOC_ID" ]; then \
		echo "Logs for allocation $$ALLOC_ID:"; \
		nomad alloc logs $$ALLOC_ID; \
	else \
		echo "No allocations found"; \
	fi

# Testing
test: ## Run all tests
	@echo "Running tests..."
	@python -m pytest tests/ -v

test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	@python -m pytest tests/unit/ -v

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	@python -m pytest tests/integration/ -v

lint: ## Lint code
	@echo "Linting code..."
	@flake8 hello.py
	@black --check hello.py

format: ## Format code
	@echo "Formatting code..."
	@black hello.py

security: ## Run security checks
	@echo "Running security checks..."
	@bandit hello.py
	@safety check

# Certificates
certs: ## Generate TLS certificates
	@echo "Generating TLS certificates..."
	@chmod +x scripts/generate-certs.sh
	@scripts/generate-certs.sh

trust-certs: ## Trust CA certificate (macOS)
	@echo "Trusting CA certificate..."
	@sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain monitoring/tls/ca.crt

# Monitoring
monitoring-setup: ## Setup monitoring stack only
	@echo "Setting up monitoring stack..."
	@docker-compose up -d loki promtail grafana prometheus

monitoring-stop: ## Stop monitoring stack
	@echo "Stopping monitoring stack..."
	@docker-compose stop loki promtail grafana prometheus

# Development
dev: ## Start development environment
	@echo "Starting development environment..."
	@APP_DEBUG=true LOG_LEVEL=debug python hello.py

dev-docker: ## Run application in Docker for development
	@echo "Running application in Docker (development)..."
	@docker run --rm -it \
		-p 8080:8080 \
		-e APP_DEBUG=true \
		-e LOG_LEVEL=debug \
		--name hello-devops-dev \
		hello-devops:latest

# Production
prod-setup: ## Setup for production
	@echo "Setting up production environment..."
	@cp .env.example .env
	@echo "Please edit .env with production values"
	@echo "Then run: make deploy"

prod-deploy: ## Deploy to production
	@echo "Deploying to production..."
	@docker-compose -f docker-compose.prod.yml up -d

# Backup and restore
backup: ## Backup all data
	@echo "Backing up data..."
	@mkdir -p backup
	@docker-compose exec prometheus tar czf /backup/prometheus-$(shell date +%Y%m%d).tar.gz /prometheus || true
	@docker-compose exec grafana tar czf /backup/grafana-$(shell date +%Y%m%d).tar.gz /var/lib/grafana || true
	@docker run --rm -v monitoring_loki-data:/data -v $$PWD/backup:/backup alpine tar czf /backup/loki-$(shell date +%Y%m%d).tar.gz -C /data .

restore: ## Restore data from backup
	@echo "Restoring data..."
	@read -p "Enter backup date (YYYYMMDD): " date; \
		docker-compose exec prometheus tar xzf /backup/prometheus-$$date.tar.gz || true; \
		docker-compose exec grafana tar xzf /backup/grafana-$$date.tar.gz || true; \
		docker run --rm -v monitoring_loki-data:/data -v $$PWD/backup:/backup alpine tar xzf /backup/loki-$$date.tar.gz -C /data

# Quick commands
quick-start: ## Quick start for demo
	@echo "Quick starting DevOps stack..."
	@make setup
	@make deploy
	@echo ""
	@echo "Services are starting..."
	@echo "Grafana: http://localhost:3000 (admin/admin)"
	@echo "Application: http://localhost:8080"
	@echo "Prometheus: http://localhost:9090"

quick-stop: ## Quick stop all services
	@echo "Quick stopping all services..."
	@make stop
	@make undeploy

# CI/CD helpers
ci-test: ## Run CI tests
	@echo "Running CI tests..."
	@make test
	@make lint
	@make security

ci-build: ## CI build
	@echo "CI build..."
	@make build-no-cache
	@make ci-test

# Utility commands
shell-app: ## Shell into application container
	@docker exec -it $$(docker ps -q -f name=hello-devops) /bin/bash

shell-grafana: ## Shell into Grafana container
	@docker exec -it grafana /bin/bash

shell-prometheus: ## Shell into Prometheus container
	@docker exec -it prometheus /bin/sh

shell-loki: ## Shell into Loki container
	@docker exec -it loki /bin/sh

# Configuration
config-check: ## Check configuration files
	@echo "Checking configuration..."
	@docker-compose config
	@nomad validate nomad/hello.nomad

config-reload: ## Reload configurations
	@echo "Reloading Prometheus configuration..."
	@curl -X POST http://localhost:9090/-/reload
	@echo "Reloading Grafana configuration..."
	@docker-compose restart grafana
