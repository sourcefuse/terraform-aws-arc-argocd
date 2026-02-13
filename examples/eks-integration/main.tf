################################################################################
## EKS Cluster Module
################################################################################

module "eks" {
  source  = "sourcefuse/arc-eks/aws"
  version = "6.0.1"

  namespace                             = var.namespace
  environment                           = var.environment
  name                                  = "${var.namespace}-${var.environment}-eks"
  kubernetes_version                    = "1.32"
  bootstrap_self_managed_addons_enabled = false

  vpc_config = {
    subnet_ids              = data.aws_subnets.private.ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  access_config = {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enable_oidc_provider = true

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  envelope_encryption = {
    enable = false
  }

  auto_mode_config = {
    enable     = true
    node_pools = ["general-purpose", "system"]
  }

  tags = var.tags
}

################################################################################
## Wait for EKS Cluster to be Ready
################################################################################

resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]

  create_duration = "120s"
}

################################################################################
## ArgoCD Module
################################################################################

module "argocd" {
  source = "../../"

  namespace   = var.namespace
  environment = var.environment

  eks_cluster_name      = module.eks.name
  eks_cluster_endpoint  = module.eks.endpoint
  eks_oidc_provider_url = module.eks.oidc_provider_url
  eks_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider_url}"
  vpc_id                = data.aws_vpc.this.id

  argocd_config = {
    enable  = true
    version = "7.8.13"

    helm_release_set_values = [
      {
        name  = "configs.cm.url"
        value = "https://${var.argocd_hostname}"
      },
      {
        name  = "configs.params.server\\.insecure"
        value = "true"
      }
    ]
  }

  ha_config = {
    enable = var.enable_ha
  }

  ingress_config = {
    enable                     = true
    host                       = var.argocd_hostname
    ingress_class_name         = "alb"
    create_acm_certificate     = var.create_acm_certificate
    acm_certificate_arn        = var.acm_certificate_arn
    install_alb_controller     = true
    auto_create_route53_record = var.auto_create_route53_record
    route53_zone_name          = var.domain_name
    alb_subnets                = data.aws_subnets.public.ids
    annotations = {
      "alb.ingress.kubernetes.io/group.name" = "${var.namespace}-${var.environment}"
    }
  }

  irsa_config = {
    enable = true
  }

  image_updater_config = {
    enable = var.enable_image_updater
  }

  tags = var.tags

  depends_on = [module.eks, time_sleep.wait_for_cluster]
}
