#!/bin/bash

# DevOps Project Setup Script
# This script sets up the entire DevOps stack with security best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="$PROJECT_DIR/monitoring/tls"
ENV_FILE="$PROJECT_DIR/.env"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if docker-compose is installed
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1; then
        print_error "docker-compose is not installed. Please install docker-compose first."
        exit 1
    fi
    print_success "docker-compose is installed"
}

# Generate certificates
generate_certificates() {
    print_status "Generating TLS certificates..."
    
    if [ ! -d "$CERT_DIR" ]; then
        mkdir -p "$CERT_DIR"
    fi
    
    # Generate CA certificate
    openssl genrsa -out "$CERT_DIR/ca.key" 4096
    openssl req -new -x509 -days 365 -key "$CERT_DIR/ca.key" -out "$CERT_DIR/ca.crt" \
        -subj "/C=US/ST=State/L=City/O=DevOps/OU=Development/CN=DevOps-CA"
    
    # Generate server certificate
    openssl genrsa -out "$CERT_DIR/server.key" 2048
    openssl req -new -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" \
        -subj "/C=US/ST=State/L=City/O=DevOps/OU=Development/CN=localhost"
    
    # Create server certificate config
    cat > "$CERT_DIR/server.conf" <<EOF
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = grafana
DNS.3 = loki
DNS.4 = prometheus
DNS.5 = promtail
IP.1 = 127.0.0.1
IP.2 = ::1
EOF
    
    # Sign server certificate
    openssl x509 -req -in "$CERT_DIR/server.csr" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
        -CAcreateserial -out "$CERT_DIR/server.crt" -days 365 \
        -extensions v3_req -extfile "$CERT_DIR/server.conf"
    
    # Clean up
    rm -f "$CERT_DIR/server.csr" "$CERT_DIR/server.conf"
    
    # Set permissions
    chmod 600 "$CERT_DIR"/*.key
    chmod 644 "$CERT_DIR"/*.crt
    
    print_success "TLS certificates generated"
}

# Setup environment file
setup_env_file() {
    print_status "Setting up environment file..."
    
    if [ ! -f "$ENV_FILE" ]; then
        cp "$PROJECT_DIR/.env.example" "$ENV_FILE"
        print_warning "Environment file created. Please edit $ENV_FILE with your values."
        
        # Generate random passwords
        LOKI_PASSWORD=$(openssl rand -base64 32)
        GRAFANA_PASSWORD=$(openssl rand -base64 32)
        PROMETHEUS_PASSWORD=$(openssl rand -base64 32)
        
        # Update environment file with generated passwords
        sed -i '' "s/your_loki_password_here/$LOKI_PASSWORD/g" "$ENV_FILE"
        sed -i '' "s/your_grafana_password_here/$GRAFANA_PASSWORD/g" "$ENV_FILE"
        sed -i '' "s/your_prometheus_password_here/$PROMETHEUS_PASSWORD/g" "$ENV_FILE"
        
        print_success "Generated random passwords for services"
    else
        print_warning "Environment file already exists. Skipping password generation."
    fi
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    
    cd "$PROJECT_DIR"
    docker build -t hello-devops:latest .
    
    print_success "Docker image built successfully"
}

# Start monitoring stack
start_monitoring() {
    print_status "Starting monitoring stack..."
    
    cd "$PROJECT_DIR"
    docker-compose up -d loki promtail grafana prometheus
    
    print_success "Monitoring stack started"
}

# Wait for services to be healthy
wait_for_services() {
    print_status "Waiting for services to be healthy..."
    
    # Wait for Loki
    print_status "Waiting for Loki..."
    timeout 60 bash -c 'until curl -f http://localhost:3100/ready >/dev/null 2>&1; do sleep 2; done'
    
    # Wait for Grafana
    print_status "Waiting for Grafana..."
    timeout 60 bash -c 'until curl -f http://localhost:3000/api/health >/dev/null 2>&1; do sleep 2; done'
    
    # Wait for Prometheus
    print_status "Waiting for Prometheus..."
    timeout 60 bash -c 'until curl -f http://localhost:9090/-/healthy >/dev/null 2>&1; do sleep 2; done'
    
    print_success "All services are healthy"
}

# Setup Nomad
setup_nomad() {
    print_status "Setting up Nomad..."
    
    # Check if Nomad is installed
    if ! command -v nomad >/dev/null 2>&1; then
        print_error "Nomad is not installed. Please install Nomad first."
        return 1
    fi
    
    # Start Nomad agent in dev mode
    if ! pgrep -f "nomad agent" >/dev/null; then
        print_status "Starting Nomad agent..."
        nomad agent -dev -bind=0.0.0.0 -network-interface=en0 &
        sleep 5
        print_success "Nomad agent started"
    else
        print_warning "Nomad agent is already running"
    fi
}

# Deploy application
deploy_app() {
    print_status "Deploying application to Nomad..."
    
    cd "$PROJECT_DIR"
    nomad job run nomad/hello.nomad
    
    print_success "Application deployed to Nomad"
}

# Show status
show_status() {
    print_status "Service Status:"
    echo ""
    
    # Docker containers
    echo "Docker Containers:"
    docker-compose ps
    echo ""
    
    # Nomad jobs
    echo "Nomad Jobs:"
    nomad job status
    echo ""
    
    # Service URLs
    echo "Service URLs:"
    echo "  Grafana:    http://localhost:3000 (admin/admin)"
    echo "  Prometheus: http://localhost:9090"
    echo "  Loki:       http://localhost:3100"
    echo "  Application: http://localhost:8080"
    echo ""
    
    print_success "Setup complete!"
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    
    # Stop services
    docker-compose down
    nomad job stop -purge hello-devops
    
    # Remove containers
    docker container prune -f
    
    print_success "Cleanup complete"
}

# Main function
main() {
    case "${1:-setup}" in
        setup)
            print_status "Starting DevOps setup..."
            check_docker
            check_docker_compose
            generate_certificates
            setup_env_file
            build_image
            start_monitoring
            wait_for_services
            setup_nomad
            deploy_app
            show_status
            ;;
        start)
            print_status "Starting services..."
            docker-compose up -d
            wait_for_services
            ;;
        stop)
            print_status "Stopping services..."
            docker-compose down
            ;;
        restart)
            print_status "Restarting services..."
            docker-compose down
            docker-compose up -d
            wait_for_services
            ;;
        rebuild)
            print_status "Rebuilding and restarting..."
            docker-compose down
            build_image
            docker-compose up -d
            wait_for_services
            ;;
        cleanup)
            cleanup
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 {setup|start|stop|restart|rebuild|cleanup|status}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
