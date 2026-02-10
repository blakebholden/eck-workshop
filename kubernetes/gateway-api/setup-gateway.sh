#!/bin/bash
# Setup script for Gateway API resources
# This script creates the necessary secrets and applies Gateway API manifests
#
# Prerequisites:
# - kubectl configured and connected to the cluster
# - ECK operator deployed and Elasticsearch/Kibana running
# - Envoy Gateway installed

set -e

NAMESPACE="elastic-system"
DOMAIN="elastic.internal"

echo "=== ECK Gateway API Setup ==="
echo ""

# Wait for ECK resources to be ready
echo "Checking ECK resources..."
kubectl wait --for=condition=Ready elasticsearch/logs -n $NAMESPACE --timeout=300s 2>/dev/null || echo "Elasticsearch logs cluster not found or not ready"
kubectl wait --for=condition=Ready kibana/kibana -n $NAMESPACE --timeout=300s 2>/dev/null || echo "Kibana not found or not ready"

# Step 1: Create Gateway TLS certificate
echo ""
echo "Step 1: Creating Gateway TLS certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/gateway-tls.key \
  -out /tmp/gateway-tls.crt \
  -subj "/CN=${DOMAIN}/O=ECK-Demo" \
  -addext "subjectAltName=DNS:*.${DOMAIN},DNS:kibana.${DOMAIN},DNS:fleet.${DOMAIN},DNS:monitoring.${DOMAIN},DNS:apm.${DOMAIN},DNS:logstash.${DOMAIN},DNS:${DOMAIN}"

kubectl create secret tls elastic-gateway-tls \
  --cert=/tmp/gateway-tls.crt \
  --key=/tmp/gateway-tls.key \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Created elastic-gateway-tls secret"

# Step 2: Create CA secrets for backend TLS (Envoy Gateway requires ca.crt key)
echo ""
echo "Step 2: Creating CA secrets for backend TLS..."

# Kibana CA (for logs Kibana)
if kubectl get secret kibana-kb-http-ca-internal -n $NAMESPACE &>/dev/null; then
  kubectl get secret kibana-kb-http-ca-internal -n $NAMESPACE -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/kibana-ca.crt
  kubectl create secret generic elastic-ca-cert -n $NAMESPACE --from-file=ca.crt=/tmp/kibana-ca.crt --dry-run=client -o yaml | kubectl apply -f -
  echo "Created elastic-ca-cert secret (from Kibana CA)"
else
  echo "WARNING: kibana-kb-http-ca-internal secret not found. Backend TLS may fail."
fi

# Monitoring Kibana CA
if kubectl get secret kibana-monitoring-kb-http-ca-internal -n $NAMESPACE &>/dev/null; then
  kubectl get secret kibana-monitoring-kb-http-ca-internal -n $NAMESPACE -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/monitoring-kibana-ca.crt
  kubectl create secret generic monitoring-kibana-ca-cert -n $NAMESPACE --from-file=ca.crt=/tmp/monitoring-kibana-ca.crt --dry-run=client -o yaml | kubectl apply -f -
  echo "Created monitoring-kibana-ca-cert secret (from Monitoring Kibana CA)"
else
  echo "WARNING: kibana-monitoring-kb-http-ca-internal secret not found. Monitoring backend TLS may fail."
fi

# Cleanup temp files
rm -f /tmp/gateway-tls.key /tmp/gateway-tls.crt /tmp/kibana-ca.crt /tmp/monitoring-kibana-ca.crt

# Step 3: Apply Gateway API manifests
echo ""
echo "Step 3: Applying Gateway API manifests..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/gatewayclass.yaml"
echo "Applied GatewayClass"

kubectl apply -f "$SCRIPT_DIR/gateway.yaml"
echo "Applied Gateway"

# Wait for Gateway to be programmed
echo "Waiting for Gateway to be ready..."
kubectl wait --for=condition=Programmed gateway/elastic-gateway -n $NAMESPACE --timeout=120s

kubectl apply -f "$SCRIPT_DIR/httproutes.yaml"
echo "Applied HTTPRoutes"

kubectl apply -f "$SCRIPT_DIR/backend-tls-policy.yaml"
echo "Applied BackendTLSPolicies"

# Step 4: Verify setup
echo ""
echo "Step 4: Verifying setup..."
echo ""
echo "Gateway status:"
kubectl get gateway -n $NAMESPACE

echo ""
echo "HTTPRoutes:"
kubectl get httproute -n $NAMESPACE

echo ""
echo "BackendTLSPolicies:"
kubectl get backendtlspolicy -n $NAMESPACE

# Get the load balancer address
echo ""
echo "=== Load Balancer Address ==="
LB_ADDRESS=$(kubectl get gateway elastic-gateway -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)
if [ -n "$LB_ADDRESS" ]; then
  echo "Gateway LB: $LB_ADDRESS"
  echo ""
  echo "Configure DNS records pointing to this address:"
  echo "  kibana.${DOMAIN}     -> $LB_ADDRESS"
  echo "  fleet.${DOMAIN}      -> $LB_ADDRESS"
  echo "  monitoring.${DOMAIN} -> $LB_ADDRESS"
  echo "  apm.${DOMAIN}        -> $LB_ADDRESS"
else
  echo "Load balancer address not yet available. Check again in a few minutes."
fi

echo ""
echo "=== Setup Complete ==="
