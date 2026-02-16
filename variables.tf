################################################################################
## Core
################################################################################

variable "namespace" {
  description = "Namespace for the resources. Used as a prefix for resource names."
  type        = string
}

variable "environment" {
  description = "ID element for the deployment environment (e.g., prod, staging, dev)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
## EKS Cluster
################################################################################

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster where ArgoCD will be installed."
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "The OIDC identity provider URL for the EKS cluster (without https:// prefix)."
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the OIDC identity provider for the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed. Required for ALB controller."
  type        = string
  default     = ""
}

################################################################################
## ArgoCD Helm Configuration
################################################################################

variable "argocd_config" {
  description = <<-EOT
    Configuration for the ArgoCD Helm release.

    - `enable`              : Toggle ArgoCD installation (default: true).
    - `name`                : Helm release name (default: "argocd").
    - `chart`               : Helm chart name (default: "argo-cd").
    - `helm_repository`     : Helm chart repository URL.
    - `version`             : Helm chart version to install.
    - `namespace`           : Kubernetes namespace for ArgoCD.
    - `create_namespace`    : Whether to create the namespace if it does not exist.
    - `timeout`             : Helm install/upgrade timeout in seconds.
    - `wait`                : Wait for all resources to be ready.
    - `atomic`              : Rollback on failure.
    - `cleanup_on_fail`     : Delete new resources on failed install.
    - `helm_release_values` : List of YAML value strings for the Helm release.
    - `helm_release_set_values` : List of individual set values [{name, value}].
  EOT

  type = object({
    enable              = optional(bool, true)
    name                = optional(string, "argocd")
    chart               = optional(string, "argo-cd")
    helm_repository     = optional(string, "https://argoproj.github.io/argo-helm")
    version             = optional(string, "7.8.13")
    namespace           = optional(string, "argocd")
    create_namespace    = optional(bool, true)
    timeout             = optional(number, 600)
    wait                = optional(bool, true)
    atomic              = optional(bool, true)
    cleanup_on_fail     = optional(bool, true)
    helm_release_values = optional(list(string), [])
    helm_release_set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })

  default = {}
}

################################################################################
## HA Configuration
################################################################################

variable "ha_config" {
  description = <<-EOT
    High availability configuration for ArgoCD.

    - `enable`          : Enable HA mode with multiple replicas (default: false).
    - `server_replicas` : Number of ArgoCD server replicas.
    - `repo_server_replicas` : Number of ArgoCD repo-server replicas.
    - `controller_replicas`  : Number of application controller replicas.
  EOT

  type = object({
    enable               = optional(bool, false)
    server_replicas      = optional(number, 2)
    repo_server_replicas = optional(number, 2)
    controller_replicas  = optional(number, 1)
  })

  default = {}
}

################################################################################
## IRSA (IAM Roles for Service Accounts)
################################################################################

variable "irsa_config" {
  description = <<-EOT
    IAM Roles for Service Accounts (IRSA) configuration.

    - `enable`                   : Create IRSA roles for ArgoCD components.
    - `server_role_name`         : IAM role name for ArgoCD server.
    - `server_policy_arns`       : Additional policy ARNs to attach to server role.
    - `repo_server_role_name`    : IAM role name for repo-server (for private ECR Helm charts, etc.).
    - `repo_server_policy_arns`  : Additional policy ARNs for repo-server role.
  EOT

  type = object({
    enable                  = optional(bool, false)
    server_role_name        = optional(string, "")
    server_policy_arns      = optional(list(string), [])
    repo_server_role_name   = optional(string, "")
    repo_server_policy_arns = optional(list(string), [])
  })

  default = {}
}

################################################################################
## Ingress / ALB
################################################################################

variable "ingress_config" {
  description = <<-EOT
    Ingress configuration for exposing ArgoCD UI.

    - `enable`             : Enable ingress resource creation via Helm values.
    - `host`               : Hostname for ArgoCD UI (e.g., argocd.example.com).
    - `ingress_class_name` : Kubernetes ingress class (default: "alb").
    - `annotations`        : Additional annotations for the ingress resource.
    - `tls_enabled`        : Enable TLS termination.
    - `acm_certificate_arn`: ACM certificate ARN for ALB HTTPS listener.
    - `install_alb_controller` : Install AWS Load Balancer Controller (default: false). Set to true if not already installed.
    - `auto_create_route53_record` : Automatically create Route53 A record for the ingress.
    - `route53_zone_name`  : Route53 hosted zone name (e.g., example.com) for automatic DNS record creation.
  EOT

  type = object({
    enable                     = optional(bool, false)
    host                       = optional(string, "")
    ingress_class_name         = optional(string, "alb")
    annotations                = optional(map(string), {})
    tls_enabled                = optional(bool, true)
    acm_certificate_arn        = optional(string, "")
    create_acm_certificate     = optional(bool, false)
    install_alb_controller     = optional(bool, false)
    auto_create_route53_record = optional(bool, false)
    route53_zone_name          = optional(string, "")
    alb_subnets                = optional(list(string), [])
  })

  default = {}
}

################################################################################
## SSO / Dex
################################################################################

variable "sso_config" {
  description = <<-EOT
    SSO / Dex configuration for ArgoCD authentication.

    - `enable`   : Enable Dex SSO integration.
    - `provider` : SSO provider type (e.g., "github", "oidc", "saml").
    - `config`   : Provider-specific configuration map (clientID, clientSecret, org, etc.).
  EOT

  type = object({
    enable   = optional(bool, false)
    provider = optional(string, "")
    config   = optional(map(string), {})
  })

  default = {}
}

################################################################################
## Notifications
################################################################################

variable "notifications_config" {
  description = <<-EOT
    ArgoCD Notifications controller configuration.

    - `enable`   : Enable the notifications controller.
    - `triggers` : Map of notification triggers.
    - `templates`: Map of notification templates.
    - `services` : Map of notification services (slack, webhook, email, etc.).
  EOT

  type = object({
    enable    = optional(bool, false)
    triggers  = optional(map(string), {})
    templates = optional(map(string), {})
    services  = optional(map(string), {})
  })

  default = {}
}

################################################################################
## Image Updater
################################################################################

variable "image_updater_config" {
  description = <<-EOT
    ArgoCD Image Updater configuration for automatic image update detection.

    - `enable`              : Deploy ArgoCD Image Updater alongside ArgoCD.
    - `chart`               : Helm chart name (default: "argocd-image-updater").
    - `version`             : Helm chart version for image updater.
    - `helm_release_values` : List of YAML value strings for image updater Helm release.
    - `registries`          : List of container registries to monitor.
  EOT

  type = object({
    enable              = optional(bool, false)
    chart               = optional(string, "argocd-image-updater")
    version             = optional(string, "0.12.0")
    helm_release_values = optional(list(string), [])
    registries = optional(list(object({
      name    = string
      api_url = string
      prefix  = string
    })), [])
  })

  default = {}
}

################################################################################
## ApplicationSet Controller
################################################################################

variable "applicationset_config" {
  description = <<-EOT
    ApplicationSet controller configuration.

    - `enable`   : Enable ApplicationSet controller (default: true — ships with ArgoCD chart).
    - `replicas` : Number of ApplicationSet controller replicas.
  EOT

  type = object({
    enable   = optional(bool, true)
    replicas = optional(number, 1)
  })

  default = {}
}

################################################################################
## Admin
################################################################################

variable "admin_config" {
  description = <<-EOT
    ArgoCD admin account configuration.

    - `disable_admin` : Disable the built-in admin user (recommended for prod with SSO).
    - `bcrypt_hash`   : Bcrypt hash of the admin password. Leave empty to auto-generate.
  EOT

  type = object({
    disable_admin = optional(bool, false)
    bcrypt_hash   = optional(string, "")
  })

  default = {}
}
