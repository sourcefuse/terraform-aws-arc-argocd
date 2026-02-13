terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
  }
}

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
  source = "../../" ## for local development

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
        name  = "configs.cm.url"
        value = "https://argocd.${var.domain_name}"
      },
      {
        name  = "configs.params.server\\.insecure"
        value = "true"
      }
    ]
  }

  ha_config = {
    enable = false
  }

  ingress_config = {
    enable                     = true
    host                       = "argocd.${var.domain_name}"
    ingress_class_name         = "alb"
    create_acm_certificate     = true # Create new certificate instead of using existing
    install_alb_controller     = true
    auto_create_route53_record = true
    route53_zone_name          = var.domain_name
    alb_subnets                = ["subnet-01efxxxxxxx", "subnet-0c55ffxxxxxx"]
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
