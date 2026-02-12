################################################################################
## Providers
################################################################################

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.this.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.this.token
#   }
# }
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}


################################################################################
## Data
################################################################################

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

################################################################################
## ArgoCD Module
################################################################################

module "argocd" {
  # source = "sourcefuse/arc-argocd/aws"
  source = "../../"  ## for local development

  namespace   = var.namespace
  environment = var.environment

  eks_cluster_name      = var.eks_cluster_name
  eks_cluster_endpoint  = data.aws_eks_cluster.this.endpoint
  eks_oidc_provider_url = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  eks_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
  vpc_id                = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  # argocd_config = {
  #   enable  = true
  #   version = "7.8.13"
  # }

  argocd_config = {
    enable  = true
    version = "7.8.13"

    helm_release_set_values = [
      {
        name  = "server.ingress.hosts[0]"
        value = "argocd-poc.${var.domain_name}"
      }
    ]
  }
  ha_config = {
    enable = false
  }

  ingress_config = {
    enable                     = true
    host                       = "argocd-poc.${var.domain_name}"
    ingress_class_name         = "alb"
    acm_certificate_arn = "arn:aws:acm:us-east-1:884360309640:certificate/1485cc03-32c5-44cc-b314-ed30642bac24"
    # acm_certificate_arn will be auto-discovered from domain
    install_alb_controller     = true  # Set to false if ALB controller already installed
    auto_create_route53_record = true
    route53_zone_name          = var.domain_name
    annotations = {
      "alb.ingress.kubernetes.io/group.name" = "${var.namespace}-${var.environment}"
    }
  }

  irsa_config = {
    enable = true
  }

  image_updater_config = {
    enable = false
  }

  tags = var.tags
}

################################################################################
## Data Sources
################################################################################

data "aws_caller_identity" "current" {}
