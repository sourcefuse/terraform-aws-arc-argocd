module "argocd" {
  source = "../../"

  namespace   = var.namespace
  environment = var.environment

  eks_cluster_name = var.eks_cluster_name

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

  ingress_config = {
    enable                     = true
    host                       = "argocd.${var.domain_name}"
    ingress_class_name         = "alb"
    create_acm_certificate     = true
    auto_create_route53_record = true
    route53_zone_name          = var.domain_name
    alb_subnets                = data.aws_subnets.public.ids
    annotations = {
      "alb.ingress.kubernetes.io/group.name" = "${var.namespace}-${var.environment}"
    }
  }

  # Define repositories
  repositories = {
    "nginx-helm-repo" = {
      url  = "https://kubernetes.github.io/ingress-nginx"
      type = "helm"
    }
    "bitnami-helm-repo" = {
      url  = "https://charts.bitnami.com/bitnami"
      type = "helm"
    }
  }

  # Define projects
  projects = {
    "demo-project" = {
      description  = "Demo project for testing"
      source_repos = ["*"]
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
    }
  }

  # Define applications
  applications = {
    "nginx-ingress" = {
      repo_url        = "https://kubernetes.github.io/ingress-nginx"
      target_revision = "4.8.3"
      path            = "ingress-nginx"
      project         = "demo-project"
      destination = {
        namespace = "ingress-nginx"
        server    = "https://kubernetes.default.svc"
      }
      helm = {
        release_name = "nginx-ingress"
        parameters = [
          {
            name  = "controller.replicaCount"
            value = "2"
          }
        ]
      }
      sync_policy = {
        automated = {
          prune     = true
          self_heal = true
        }
        sync_options = ["CreateNamespace=true"]
      }
    }
  }

  tags = var.tags
}
