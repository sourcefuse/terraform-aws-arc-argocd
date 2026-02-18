################################################################################
## Get ALB DNS Name from Ingress
################################################################################

data "kubernetes_ingress_v1" "argocd" {
  count = var.ingress_config.enable && var.ingress_config.auto_create_route53_record ? 1 : 0

  metadata {
    name      = "${var.argocd_config.name}-server"
    namespace = local.argocd_namespace
  }

  depends_on = [helm_release.argocd]
}

################################################################################
## Get Route53 Hosted Zone
################################################################################

data "aws_route53_zone" "this" {
  count = var.ingress_config.enable && var.ingress_config.auto_create_route53_record && var.ingress_config.route53_zone_name != "" ? 1 : 0

  name         = var.ingress_config.route53_zone_name
  private_zone = false
}

################################################################################
## Create Route53 Record (only after ALB is provisioned)
################################################################################

resource "aws_route53_record" "argocd" {
  count = var.ingress_config.enable && var.ingress_config.auto_create_route53_record && var.ingress_config.route53_zone_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.ingress_config.host
  type    = "A"

  alias {
    name                   = try(data.kubernetes_ingress_v1.argocd[0].status[0].load_balancer[0].ingress[0].hostname, "")
    zone_id                = local.alb_zone_id
    evaluate_target_health = true
  }

  depends_on = [helm_release.argocd]

  lifecycle {
    ignore_changes = [alias[0].name]
  }
}
