# AWS ALB Ingress (Alternative Approach)

> **Note**: This is the AWS-specific alternative. For portable deployments that work on both EKS and VKS, use the [Gateway API approach](../gateway-api/).

## Overview

Uses AWS Load Balancer Controller to create internal Application Load Balancers for Kibana and Fleet Server.

## Prerequisites

1. **AWS Load Balancer Controller** installed in cluster
2. **ACM Certificate** for `*.elastic.internal`
3. **Route53 Private Hosted Zone** for `elastic.internal`
4. **IAM permissions** for the controller

## Installation

### 1. Install AWS Load Balancer Controller

```bash
# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eck-demo \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::ACCOUNT:role/alb-controller-role
```

### 2. Create ACM Certificate

```bash
# Request certificate
aws acm request-certificate \
  --domain-name "*.elastic.internal" \
  --validation-method DNS \
  --region us-east-2

# Note the certificate ARN and update ingress.yaml
```

### 3. Apply Ingress

```bash
# Update certificate ARN in ingress.yaml first!
kubectl apply -f ingress.yaml
```

### 4. Configure DNS

After the ALB is created:

```bash
# Get ALB DNS name
kubectl get ingress -n elastic-system kibana-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create Route53 records (or use Terraform)
```

## Comparison with Gateway API

| Aspect | ALB Ingress | Gateway API |
|--------|-------------|-------------|
| Portability | AWS only | EKS + VKS |
| Management | AWS managed | Self-managed |
| Configuration | Annotations | Standard CRDs |
| TCP/UDP | Limited | Full support |
| Cost | ALB charges | NLB + pods |

## When to Use ALB Ingress

- AWS-only deployment
- Want AWS-managed load balancer
- Already using ALB for other services
- Need ALB-specific features (WAF, etc.)

## Files

- `ingress.yaml` - Ingress resources for Kibana and Fleet Server
