output "argocd_server_url" {
  description = "ArgoCD server URL."
  value       = module.argocd.argocd_server_url
}

output "argocd_status" {
  description = "Helm release status."
  value       = module.argocd.status
}

output "server_iam_role_arn" {
  description = "IRSA role ARN for ArgoCD server."
  value       = module.argocd.server_iam_role_arn
}
