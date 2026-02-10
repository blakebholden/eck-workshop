# Route53 Private Hosted Zone
# Simulates customer's private DNS environment
# DNS names only resolve within the associated VPC

resource "aws_route53_zone" "private" {
  name = var.domain

  # Private hosted zone - only resolves within VPC
  vpc {
    vpc_id = var.vpc_id
  }

  comment = "Private DNS zone for Elastic services - mirrors on-prem private DNS pattern"

  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-private-zone"
  })
}

# Kibana DNS record - CNAME pointing to Gateway's NLB
resource "aws_route53_record" "kibana" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "kibana.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.gateway_lb_hostname]
}

# Fleet Server DNS record
resource "aws_route53_record" "fleet" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "fleet.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.gateway_lb_hostname]
}

# Monitoring Kibana DNS record
resource "aws_route53_record" "monitoring" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "monitoring.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.gateway_lb_hostname]
}

# APM Server DNS record
resource "aws_route53_record" "apm" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "apm.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.gateway_lb_hostname]
}

# Elasticsearch DNS record (optional - usually internal only)
resource "aws_route53_record" "elasticsearch" {
  count = var.create_es_record ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = "es.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.gateway_lb_hostname]
}

# Wildcard record for flexibility
resource "aws_route53_record" "wildcard" {
  count = var.create_wildcard ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = "*.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.gateway_lb_hostname]
}
