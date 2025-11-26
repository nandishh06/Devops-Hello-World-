#!/bin/bash

# Certificate generation script for development environment
# Usage: ./scripts/generate-certs.sh

set -e

CERT_DIR="monitoring/tls"
DOMAIN="localhost"
VALIDITY_DAYS=365

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Generating self-signed certificates for development...${NC}"

# Create certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Generate CA certificate
echo -e "${YELLOW}Generating CA certificate...${NC}"
openssl genrsa -out "$CERT_DIR/ca.key" 4096
openssl req -new -x509 -days "$VALIDITY_DAYS" -key "$CERT_DIR/ca.key" -out "$CERT_DIR/ca.crt" \
    -subj "/C=US/ST=State/L=City/O=DevOps/OU=Development/CN=DevOps-CA"

# Generate server certificate
echo -e "${YELLOW}Generating server certificate...${NC}"
openssl genrsa -out "$CERT_DIR/server.key" 2048
openssl req -new -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" \
    -subj "/C=US/ST=State/L=City/O=DevOps/OU=Development/CN=$DOMAIN"

# Create server certificate config
cat > "$CERT_DIR/server.conf" <<EOF
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
DNS.2 = localhost
DNS.3 = grafana
DNS.4 = loki
DNS.5 = prometheus
DNS.6 = promtail
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Sign server certificate
openssl x509 -req -in "$CERT_DIR/server.csr" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
    -CAcreateserial -out "$CERT_DIR/server.crt" -days "$VALIDITY_DAYS" \
    -extensions v3_req -extfile "$CERT_DIR/server.conf"

# Generate client certificate for Promtail
echo -e "${YELLOW}Generating client certificate for Promtail...${NC}"
openssl genrsa -out "$CERT_DIR/promtail.key" 2048
openssl req -new -key "$CERT_DIR/promtail.key" -out "$CERT_DIR/promtail.csr" \
    -subj "/C=US/ST=State/L=City/O=DevOps/OU=Development/CN=promtail"

# Sign client certificate
openssl x509 -req -in "$CERT_DIR/promtail.csr" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
    -CAcreateserial -out "$CERT_DIR/promtail.crt" -days "$VALIDITY_DAYS"

# Generate client certificate for Grafana
echo -e "${YELLOW}Generating client certificate for Grafana...${NC}"
openssl genrsa -out "$CERT_DIR/grafana.key" 2048
openssl req -new -key "$CERT_DIR/grafana.key" -out "$CERT_DIR/grafana.csr" \
    -subj "/C=US/ST=State/L=City/O=DevOps/OU=Development/CN=grafana"

# Sign client certificate
openssl x509 -req -in "$CERT_DIR/grafana.csr" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
    -CAcreateserial -out "$CERT_DIR/grafana.crt" -days "$VALIDITY_DAYS"

# Clean up temporary files
rm -f "$CERT_DIR/server.csr" "$CERT_DIR/promtail.csr" "$CERT_DIR/grafana.csr" "$CERT_DIR/server.conf"

# Set appropriate permissions
chmod 600 "$CERT_DIR"/*.key
chmod 644 "$CERT_DIR"/*.crt
chmod 644 "$CERT_DIR/ca.srl"

echo -e "${GREEN}Certificates generated successfully!${NC}"
echo -e "${YELLOW}Certificate files:${NC}"
ls -la "$CERT_DIR"
echo ""
echo -e "${GREEN}To trust the CA certificate on macOS:${NC}"
echo "sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CERT_DIR/ca.crt"
echo ""
echo -e "${GREEN}To trust the CA certificate on Linux:${NC}"
echo "sudo cp $CERT_DIR/ca.crt /usr/local/share/ca-certificates/"
echo "sudo update-ca-certificates"
echo ""
echo -e "${YELLOW}WARNING: These are self-signed certificates for development only!${NC}"
echo -e "${YELLOW}Do NOT use these certificates in production!${NC}"
