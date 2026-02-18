variable "namespace" {
  description = "Namespace for the resources."
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "argocd_hostname" {
  description = "Hostname for ArgoCD UI (e.g., argocd.example.com)."
  type        = string
  default     = "argocd-poc2.arc-poc.link"
}

variable "domain_name" {
  description = "Domain name for ArgoCD ingress."
  type        = string
  default     = "arc-poc.link"
}

variable "auto_create_route53_record" {
  description = "Automatically create Route53 A record for ArgoCD."
  type        = bool
  default     = true
}

variable "create_acm_certificate" {
  description = "Create new ACM certificate for ArgoCD."
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "Existing ACM certificate ARN (if not creating new)."
  type        = string
  default     = ""
}

variable "enable_ha" {
  description = "Enable high availability mode for ArgoCD."
  type        = bool
  default     = false
}

variable "enable_image_updater" {
  description = "Enable ArgoCD Image Updater."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Project   = "arc"
    ManagedBy = "terraform"
  }
}
