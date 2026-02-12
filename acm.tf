################################################################################
## Find ACM Certificate (optional)
################################################################################

data "aws_acm_certificate" "this" {
  count = var.ingress_config.enable && var.ingress_config.acm_certificate_arn == "" && var.ingress_config.host != "" ? 1 : 0

  domain      = var.ingress_config.host
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "wildcard" {
  count = var.ingress_config.enable && var.ingress_config.acm_certificate_arn == "" && var.ingress_config.host != "" ? 1 : 0

  domain      = "*.${join(".", slice(split(".", var.ingress_config.host), 1, length(split(".", var.ingress_config.host))))}"
  statuses    = ["ISSUED"]
  most_recent = true
}

locals {
  acm_certificate_arn = var.ingress_config.acm_certificate_arn != "" ? var.ingress_config.acm_certificate_arn : try(data.aws_acm_certificate.this[0].arn, try(data.aws_acm_certificate.wildcard[0].arn, ""))
}
