################################################################################
## EKS Cluster Outputs
################################################################################

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster API server."
  value       = module.eks.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster."
  value       = module.eks.eks_cluster_security_group_id
}

output "oidc_provider_url" {
  description = "OIDC provider URL for the EKS cluster."
  value       = module.eks.oidc_provider_url
}

################################################################################
## ArgoCD Outputs
################################################################################

output "argocd_server_url" {
  description = "URL to access ArgoCD UI."
  value       = module.argocd.argocd_server_url
}

output "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is installed."
  value       = module.argocd.namespace
}

output "argocd_status" {
  description = "Status of the ArgoCD Helm release."
  value       = module.argocd.status
}

output "argocd_server_iam_role_arn" {
  description = "IAM role ARN for ArgoCD server."
  value       = module.argocd.server_iam_role_arn
}

output "argocd_repo_server_iam_role_arn" {
  description = "IAM role ARN for ArgoCD repo-server."
  value       = module.argocd.repo_server_iam_role_arn
}

output "route53_record_fqdn" {
  description = "FQDN of the Route53 record for ArgoCD."
  value       = module.argocd.route53_record_fqdn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN used for ArgoCD ingress."
  value       = module.argocd.acm_certificate_arn
}
