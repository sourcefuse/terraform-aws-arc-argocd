################################################################################
## Create ACM Certificate (optional)
################################################################################

resource "aws_acm_certificate" "argocd" {
  count = var.ingress_config.enable && var.ingress_config.create_acm_certificate && var.ingress_config.host != "" ? 1 : 0

  domain_name       = var.ingress_config.host
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = var.ingress_config.enable && var.ingress_config.create_acm_certificate && var.ingress_config.auto_create_route53_record ? {
    for dvo in aws_acm_certificate.argocd[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this[0].zone_id
}

resource "aws_acm_certificate_validation" "argocd" {
  count = var.ingress_config.enable && var.ingress_config.create_acm_certificate && var.ingress_config.auto_create_route53_record ? 1 : 0

  certificate_arn         = aws_acm_certificate.argocd[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

################################################################################
## Find ACM Certificate (optional)
################################################################################

data "aws_acm_certificate" "this" {
  count = var.ingress_config.enable && !var.ingress_config.create_acm_certificate && var.ingress_config.acm_certificate_arn == "" && var.ingress_config.host != "" ? 1 : 0

  domain      = var.ingress_config.host
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "wildcard" {
  count = var.ingress_config.enable && !var.ingress_config.create_acm_certificate && var.ingress_config.acm_certificate_arn == "" && var.ingress_config.host != "" ? 1 : 0

  domain      = "*.${join(".", slice(split(".", var.ingress_config.host), 1, length(split(".", var.ingress_config.host))))}"
  statuses    = ["ISSUED"]
  most_recent = true
}

locals {
  acm_certificate_arn = var.ingress_config.create_acm_certificate ? try(aws_acm_certificate.argocd[0].arn, "") : (
    var.ingress_config.acm_certificate_arn != "" ? var.ingress_config.acm_certificate_arn : try(data.aws_acm_certificate.this[0].arn, try(data.aws_acm_certificate.wildcard[0].arn, ""))
  )
}
