# Skill: Gateway & Ingress Deep Dive

Load this skill when students ask "tell me more" about gateway, ingress, or load balancers, or when they're confused about how traffic reaches their services.

## Overview

This skill explains:
1. What problem Ingress/Gateway solves
2. The difference between Ingress and Gateway API
3. How Envoy Gateway works
4. How traffic flows from the internet to your pods

---

## The Problem: How Does Traffic Get In?

```
When you deploy an application in Kubernetes, it runs inside the cluster.
But how do users on the internet access it?

The Problem:
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                          │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐            │
│   │  Pod A  │    │  Pod B  │    │  Pod C  │            │
│   │ (Kibana)│    │  (ES)   │    │ (Fleet) │            │
│   └─────────┘    └─────────┘    └─────────┘            │
│        ↑                                                │
│        │ How does this get accessed?                    │
│        │                                                │
└────────┼────────────────────────────────────────────────┘
         │
    ?????│?????
         │
    ┌────┴────┐
    │  User   │
    │(Browser)│
    └─────────┘
```

**Options to expose services:**

1. **NodePort** - Opens a port on every node (30000-32767)
   - Simple but requires knowing node IPs
   - Not great for production

2. **LoadBalancer** - Creates a cloud load balancer per service
   - Easy but expensive ($18/month per LB on AWS!)
   - One LB per service adds up fast

3. **Ingress/Gateway** - Single load balancer, routes by URL path
   - One LB handles multiple services
   - Routes: `/kibana` → Kibana, `/elasticsearch` → ES
   - Most cost-effective and flexible
```

---

## Ingress vs Gateway API

```
## Traditional Ingress (older approach)

The Ingress resource has been around since Kubernetes 1.1. It works but
has limitations:

- Limited to HTTP/HTTPS only
- Annotations vary by controller (nginx, traefik, etc.)
- No standard way to configure advanced features
- Single resource type for everything

## Gateway API (modern approach)

Gateway API is the evolution of Ingress. It's:

- Multi-protocol (HTTP, HTTPS, TCP, UDP, gRPC)
- Standardized across implementations
- Role-based (platform admin vs app developer separation)
- More expressive and powerful

Key resources:
- **GatewayClass** - Defines which controller to use
- **Gateway** - The actual entry point (creates Load Balancer)
- **HTTPRoute** - Routes HTTP traffic to services
- **TCPRoute/UDPRoute** - For non-HTTP protocols

We use Gateway API in this workshop because it's the future of
Kubernetes ingress and Envoy Gateway implements it well.
```

---

## How Envoy Gateway Works

```
## What is Envoy?

Envoy is a high-performance proxy originally built by Lyft. It's used by:
- Istio (service mesh)
- AWS App Mesh
- Many other cloud-native projects

## Envoy Gateway

Envoy Gateway is an official Envoy project that implements the
Kubernetes Gateway API using Envoy as the data plane.

Architecture:
┌──────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                 │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                Network Load Balancer (NLB)                   │ │
│  │                    (AWS Managed)                             │ │
│  └─────────────────────────┬───────────────────────────────────┘ │
│                            │                                      │
│  ┌─────────────────────────┼───────────────────────────────────┐ │
│  │          Kubernetes Cluster                                  │ │
│  │                         │                                    │ │
│  │                         ▼                                    │ │
│  │  ┌─────────────────────────────────────────────┐            │ │
│  │  │          Envoy Gateway Pod                   │            │ │
│  │  │  ┌─────────────────────────────────────┐    │            │ │
│  │  │  │        Envoy Proxy                   │    │            │ │
│  │  │  │                                      │    │            │ │
│  │  │  │  Route: kibana.elastic.internal      │    │            │ │
│  │  │  │         → kibana-kb-http:5601        │    │            │ │
│  │  │  │                                      │    │            │ │
│  │  │  │  Route: fleet.elastic.internal       │    │            │ │
│  │  │  │         → fleet-server-http:8220     │    │            │ │
│  │  │  └─────────────────────────────────────┘    │            │ │
│  │  └─────────────────────────────────────────────┘            │ │
│  │                         │                                    │ │
│  │           ┌─────────────┼─────────────┐                     │ │
│  │           │             │             │                     │ │
│  │           ▼             ▼             ▼                     │ │
│  │     ┌─────────┐   ┌─────────┐   ┌─────────┐                │ │
│  │     │ Kibana  │   │  Fleet  │   │   ES    │                │ │
│  │     │  Pod    │   │ Server  │   │   Pod   │                │ │
│  │     └─────────┘   └─────────┘   └─────────┘                │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

Traffic Flow:
1. User requests kibana.elastic.internal
2. DNS resolves to NLB IP
3. NLB forwards to Envoy Gateway pod
4. Envoy matches the hostname to an HTTPRoute
5. Envoy forwards to the Kibana service
6. Kibana responds back through the chain
```

---

## The Gateway Resources We Create

```
## 1. GatewayClass (created by Envoy Gateway install)

Tells Kubernetes "use Envoy Gateway for Gateway resources":

apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller

## 2. Gateway (creates the Load Balancer)

This is the "front door" - it creates the actual NLB:

apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: elastic-gateway
  namespace: elastic-system
spec:
  gatewayClassName: eg
  listeners:
    - name: https
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - name: gateway-tls-cert

When you create this, AWS provisions a Network Load Balancer.
This is why it takes 3-5 minutes!

## 3. HTTPRoute (routes traffic to services)

Defines which requests go where:

apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: kibana-route
spec:
  parentRefs:
    - name: elastic-gateway
  hostnames:
    - "kibana.elastic.internal"
  rules:
    - backendRefs:
        - name: kibana-kb-http
          port: 5601

This says: "requests for kibana.elastic.internal go to the kibana service"
```

---

## Why Does the Load Balancer Take So Long?

```
When you create a Gateway, here's what happens in AWS:

1. **Kubernetes sees the Gateway resource** (instant)

2. **Envoy Gateway controller processes it** (~10 seconds)
   - Validates the configuration
   - Creates the Envoy deployment
   - Requests a LoadBalancer Service

3. **AWS Load Balancer Controller sees the Service** (~10 seconds)
   - Determines it needs an NLB
   - Calls AWS APIs to create it

4. **AWS provisions the NLB** (3-5 minutes!)
   - Creates the load balancer resource
   - Provisions network interfaces in each AZ
   - Configures health checks
   - Registers targets
   - Waits for health checks to pass

5. **DNS propagates** (~30 seconds)
   - The NLB gets a DNS name
   - We create Route53 records pointing to it

That's why we start this early - the NLB provisioning is the slowest part!
```

---

## Checking Gateway Status

```bash
# See the Gateway and its status
kubectl get gateway -n elastic-system

# Expected output when ready:
NAME              CLASS   ADDRESS                                      READY
elastic-gateway   eg      k8s-elastic-xxxxx.elb.us-east-2.amazonaws.com   True

# If ADDRESS is empty, the NLB is still provisioning

# See the HTTPRoutes
kubectl get httproute -n elastic-system

# Check the actual NLB in AWS
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-elastic')]"
```

---

## Common Gateway Issues

### Gateway stuck with no ADDRESS

**Cause**: NLB still provisioning or failed.

**Check**:
```bash
# Look at gateway events
kubectl describe gateway elastic-gateway -n elastic-system

# Check the envoy gateway controller logs
kubectl logs -n envoy-gateway-system -l app.kubernetes.io/name=envoy-gateway
```

### HTTPRoute not working

**Cause**: Backend service doesn't exist or TLS mismatch.

**Check**:
```bash
# Verify the backend service exists
kubectl get svc -n elastic-system

# Check route status
kubectl describe httproute <route-name> -n elastic-system
```

### "Connection refused" through gateway

**Cause**: Backend TLS policy mismatch or service not ready.

**Check**:
```bash
# Are the backend pods running?
kubectl get pods -n elastic-system

# Is the service endpoint populated?
kubectl get endpoints <service-name> -n elastic-system
```

---

## Private DNS with Route53

```
In this workshop, we use PRIVATE DNS. Here's why:

## Public DNS
- Accessible from the internet
- Anyone can resolve the hostname
- Requires proper TLS certificates from a public CA

## Private DNS (what we use)
- Only accessible from within the VPC
- Route53 Private Hosted Zone
- Self-signed certificates are fine
- More secure - services aren't exposed publicly

Our setup:
┌─────────────────────────────────────────────────────────────┐
│                          VPC                                 │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Route53 Private Hosted Zone                  │  │
│  │                                                        │  │
│  │   kibana.elastic.internal → NLB IP                    │  │
│  │   fleet.elastic.internal  → NLB IP                    │  │
│  │   es.elastic.internal     → NLB IP                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  Only resources IN this VPC can resolve these names!        │
│                                                              │
│  ┌─────────┐                         ┌─────────┐           │
│  │ Jumpbox │ ← Can access            │ Your    │           │
│  │ (in VPC)│   kibana.elastic.internal laptop  │ ← Cannot  │
│  └─────────┘                         │(outside)│   access  │
│                                      └─────────┘           │
└─────────────────────────────────────────────────────────────┘

To access Kibana from your laptop, you need to either:
1. Use port-forwarding (kubectl port-forward)
2. Connect through the Windows jumpbox (RDP)
3. Use a VPN into the VPC
```

---

## Summary

```
Key Takeaways:

1. **Gateway API** is the modern way to expose services
2. **Envoy Gateway** implements Gateway API using Envoy proxy
3. **Load Balancers take 3-5 minutes** to provision - start early!
4. **HTTPRoutes** define which requests go to which services
5. **Private DNS** keeps services secure within the VPC
6. **Use the jumpbox or port-forward** to access from outside

Questions? Ask "tell me more" about any specific component!
```
