locals {
  name = "${var.namespace}-${var.environment}-argocd"

  common_tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "terraform-aws-arc-argocd"
  })

  argocd_namespace = var.argocd_config.namespace

  ################################################################################
  ## IRSA
  ################################################################################

  irsa_server_role_name      = var.irsa_config.server_role_name != "" ? var.irsa_config.server_role_name : "${local.name}-server"
  irsa_repo_server_role_name = var.irsa_config.repo_server_role_name != "" ? var.irsa_config.repo_server_role_name : "${local.name}-repo-server"

  ################################################################################
  ## HA Helm values
  ################################################################################

  ha_values = var.ha_config.enable ? {
    "server.replicas"              = tostring(var.ha_config.server_replicas)
    "repoServer.replicas"          = tostring(var.ha_config.repo_server_replicas)
    "controller.replicas"          = tostring(var.ha_config.controller_replicas)
    "redis-ha.enabled"             = "true"
    "redis.enabled"                = "false"
    "controller.enableStatefulSet" = "true"
  } : {}

  ################################################################################
  ## Ingress Helm values
  ################################################################################

  default_alb_annotations = var.ingress_config.enable ? merge({
    "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"      = "ip"
    "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\":443}]"
    "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    },
    local.acm_certificate_arn != "" ? {
      "alb.ingress.kubernetes.io/certificate-arn" = local.acm_certificate_arn
    } : {},
    var.ingress_config.tls_enabled ? {
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
    } : {}
  ) : {}

  ingress_annotations = var.ingress_config.enable ? merge(local.default_alb_annotations, var.ingress_config.annotations) : {}

  ingress_values = var.ingress_config.enable ? {
    "server.ingress.enabled"          = "true"
    "server.ingress.ingressClassName" = var.ingress_config.ingress_class_name
  } : {}

  ################################################################################
  ## SSO Helm values
  ################################################################################

  sso_values = var.sso_config.enable ? {
    "dex.enabled" = "true"
  } : {}

  ################################################################################
  ## Notifications Helm values
  ################################################################################

  notifications_values = var.notifications_config.enable ? {
    "notifications.enabled" = "true"
  } : {}

  ################################################################################
  ## ApplicationSet Helm values
  ################################################################################

  applicationset_values = {
    "applicationSet.enabled"  = tostring(var.applicationset_config.enable)
    "applicationSet.replicas" = tostring(var.applicationset_config.replicas)
  }

  ################################################################################
  ## Admin values
  ################################################################################

  admin_values = var.admin_config.disable_admin ? {
    "configs.params.server\\.disable\\.auth" = "false"
  } : {}

  ################################################################################
  ## IRSA annotations for service accounts
  ################################################################################

  irsa_values = var.irsa_config.enable ? {
    "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"     = aws_iam_role.argocd_server[0].arn
    "repoServer.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.argocd_repo_server[0].arn
  } : {}

  ################################################################################
  ## Merged set values
  ################################################################################

  required_set_values = [
    for k, v in merge(
      local.ha_values,
      local.ingress_values,
      local.sso_values,
      local.notifications_values,
      local.applicationset_values,
      local.admin_values,
      local.irsa_values,
    ) : {
      name  = k
      value = v
    }
  ]

  merged_set_values = concat(local.required_set_values, var.argocd_config.helm_release_set_values)

  ################################################################################
  ## ALB Zone ID mapping by region
  ################################################################################

  alb_zone_id = lookup({
    "us-east-1"      = "Z35SXDOTRQ7X7K"
    "us-east-2"      = "Z3AADJGX6KTTL2"
    "us-west-1"      = "Z368ELLRRE2KJ0"
    "us-west-2"      = "Z1H1FL5HABSF5"
    "ca-central-1"   = "ZQSVJUPU6J1EY"
    "eu-central-1"   = "Z215JYRZR1TBD5"
    "eu-west-1"      = "Z32O12XQLNTSW2"
    "eu-west-2"      = "ZHURV8PSTC4K8"
    "eu-west-3"      = "Z3Q77PNBQS71R4"
    "eu-north-1"     = "Z23TAZ6LKFMNIO"
    "ap-northeast-1" = "Z14GRHDCWA56QT"
    "ap-northeast-2" = "ZWKZPGTI48KDX"
    "ap-southeast-1" = "Z1LMS91P8CMLE5"
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"
    "ap-south-1"     = "ZP97RAFLXTNZK"
    "sa-east-1"      = "Z2P70J7HTTTPLU"
  }, data.aws_region.current.id, "Z35SXDOTRQ7X7K")
}
