################################################################################
## ArgoCD Outputs
################################################################################

output "name" {
  description = "The name of the ArgoCD Helm release."
  value       = var.argocd_config.enable ? helm_release.argocd[0].name : null
}

output "namespace" {
  description = "The Kubernetes namespace where ArgoCD is installed."
  value       = var.argocd_config.enable ? helm_release.argocd[0].namespace : null
}

output "chart_version" {
  description = "The ArgoCD Helm chart version deployed."
  value       = var.argocd_config.enable ? helm_release.argocd[0].version : null
}

output "status" {
  description = "Status of the ArgoCD Helm release."
  value       = var.argocd_config.enable ? helm_release.argocd[0].status : null
}

output "argocd_server_url" {
  description = "The ArgoCD server URL (based on ingress host or cluster-internal service)."
  value = var.ingress_config.enable && var.ingress_config.host != "" ? (
    "https://${var.ingress_config.host}"
  ) : "https://argocd-server.${local.argocd_namespace}.svc.cluster.local"
}

################################################################################
## IRSA Outputs
################################################################################

output "server_iam_role_arn" {
  description = "ARN of the IAM role for the ArgoCD server service account."
  value       = var.irsa_config.enable ? aws_iam_role.argocd_server[0].arn : null
}

output "repo_server_iam_role_arn" {
  description = "ARN of the IAM role for the ArgoCD repo-server service account."
  value       = var.irsa_config.enable ? aws_iam_role.argocd_repo_server[0].arn : null
}

################################################################################
## Image Updater Outputs
################################################################################

output "image_updater_status" {
  description = "Status of the ArgoCD Image Updater Helm release."
  value       = var.image_updater_config.enable ? helm_release.argocd_image_updater[0].status : null
}

################################################################################
## Route53 Outputs
################################################################################

output "route53_record_fqdn" {
  description = "FQDN of the Route53 record created for ArgoCD."
  value       = var.ingress_config.auto_create_route53_record ? try(aws_route53_record.argocd[0].fqdn, null) : null
}

output "alb_dns_name" {
  description = "DNS name of the ALB created for ArgoCD ingress."
  value       = var.ingress_config.enable ? try(data.kubernetes_ingress_v1.argocd[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN used for ArgoCD ingress."
  value       = var.ingress_config.enable ? local.acm_certificate_arn : null
}

################################################################################
## ArgoCD Resources Outputs
################################################################################

output "repositories" {
  description = "Map of created ArgoCD repositories."
  value       = { for k, v in kubectl_manifest.argocd_repository : k => k }
}

output "projects" {
  description = "Map of created ArgoCD projects."
  value       = { for k, v in kubectl_manifest.argocd_project : k => k }
}

output "applications" {
  description = "Map of created ArgoCD applications."
  value       = { for k, v in kubectl_manifest.argocd_application : k => k }
}
