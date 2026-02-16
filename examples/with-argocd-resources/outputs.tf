output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = module.argocd.argocd_server_url
}

output "repositories" {
  description = "Created ArgoCD repositories"
  value       = module.argocd.repositories
}

output "projects" {
  description = "Created ArgoCD projects"
  value       = module.argocd.projects
}

output "applications" {
  description = "Created ArgoCD applications"
  value       = module.argocd.applications
}
