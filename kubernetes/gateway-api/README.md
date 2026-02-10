# Gateway API Configuration

This directory contains **portable** Gateway API manifests that work on both:
- **AWS EKS** (with Envoy Gateway + NLB)
- **VMware VKS** (with Envoy Gateway + MetalLB or similar)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PORTABLE MANIFESTS                              │
│  ┌──────────────┐    ┌──────────────┐    ┌────────────────────────────┐ │
│  │ GatewayClass │ →  │   Gateway    │ →  │ HTTPRoute / TCPRoute       │ │
│  │ (envoy-gw)   │    │ (elastic-gw) │    │ (kibana, fleet, es)        │ │
│  └──────────────┘    └──────────────┘    └────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                               │
          ┌────────────────────┴────────────────────┐
          ▼                                         ▼
     ┌─────────┐                              ┌──────────┐
     │   EKS   │                              │   VKS    │
     │   NLB   │ (internal)                   │ MetalLB  │
     └─────────┘                              └──────────┘
          │                                         │
   Route53 Private                           On-Prem DNS
   Hosted Zone                               (customer's)
```

## Files

| File | Purpose | Portable? |
|------|---------|-----------|
| `gatewayclass.yaml` | Defines Envoy Gateway controller | Yes |
| `gateway.yaml` | Main gateway with listeners | Yes* |
| `httproutes.yaml` | Routes for Kibana, Fleet, etc. | **100% Yes** |
| `tls-secret.yaml` | TLS certificate (template) | Yes |

*Gateway has optional AWS annotations that are ignored on VKS

## Deployment Order

1. Install Envoy Gateway (Helm)
2. Apply GatewayClass
3. Create TLS secret
4. Apply Gateway
5. Apply HTTPRoutes

## Environment Differences

### AWS EKS
- Gateway Service gets internal NLB automatically
- Route53 Private Hosted Zone for DNS
- TLS can use ACM or self-signed

### VMware VKS
- Gateway Service gets IP from MetalLB
- Customer's private DNS for resolution
- TLS uses customer's PKI

## Quick Start

```bash
# Install Envoy Gateway
helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.2.4 \
  -n envoy-gateway-system --create-namespace

# Apply manifests
kubectl apply -f gatewayclass.yaml
kubectl apply -f tls-secret.yaml  # Edit with your certs first
kubectl apply -f gateway.yaml
kubectl apply -f httproutes.yaml

# Verify
kubectl get gatewayclass
kubectl get gateway -n elastic-system
kubectl get httproute -n elastic-system
```
