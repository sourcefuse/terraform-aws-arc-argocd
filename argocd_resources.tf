################################################################################
## Wait for ArgoCD CRDs to be ready
################################################################################

resource "time_sleep" "wait_for_argocd_crds" {
  count = var.argocd_config.enable && (length(var.repositories) > 0 || length(var.projects) > 0 || length(var.applications) > 0) ? 1 : 0

  create_duration = "45s"

  depends_on = [helm_release.argocd]
}

################################################################################
## ArgoCD Repositories
################################################################################

resource "kubectl_manifest" "argocd_repository" {
  for_each = var.repositories

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = each.key
      namespace = local.argocd_namespace
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    stringData = merge(
      {
        url  = each.value.url
        type = try(each.value.type, "git")
      },
      each.value.username != null ? { username = each.value.username } : {},
      each.value.password != null ? { password = each.value.password } : {},
      each.value.ssh_private_key != null ? { sshPrivateKey = each.value.ssh_private_key } : {},
      each.value.insecure != null ? { insecure = tostring(each.value.insecure) } : {},
      each.value.enable_lfs != null ? { enableLfs = tostring(each.value.enable_lfs) } : {}
    )
  })

  depends_on = [helm_release.argocd]
}

################################################################################
## ArgoCD Projects
################################################################################

resource "kubectl_manifest" "argocd_project" {
  for_each = var.projects

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = each.key
      namespace = local.argocd_namespace
    }
    spec = {
      description = try(each.value.description, "")
      sourceRepos = try(each.value.source_repos, ["*"])
      destinations = try(each.value.destinations, [
        {
          namespace = "*"
          server    = "*"
        }
      ])
      clusterResourceWhitelist = try(each.value.cluster_resource_whitelist, [
        {
          group = "*"
          kind  = "*"
        }
      ])
      namespaceResourceWhitelist = try(each.value.namespace_resource_whitelist, [
        {
          group = "*"
          kind  = "*"
        }
      ])
    }
  })

  depends_on = [
    helm_release.argocd,
    time_sleep.wait_for_argocd_crds
  ]
}

################################################################################
## ArgoCD Applications
################################################################################

resource "kubectl_manifest" "argocd_application" {
  for_each = var.applications

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.key
      namespace = local.argocd_namespace
      finalizers = try(each.value.finalizers, [
        "resources-finalizer.argocd.argoproj.io"
      ])
    }
    spec = {
      project = try(each.value.project, "default")
      source = {
        repoURL        = each.value.repo_url
        targetRevision = try(each.value.target_revision, "HEAD")
        path           = try(each.value.path, "")
        helm = try(each.value.helm, null) != null ? {
          releaseName = try(each.value.helm.release_name, null)
          values      = try(each.value.helm.values, null)
          valueFiles  = try(each.value.helm.value_files, null)
          parameters = try(each.value.helm.parameters, null) != null ? [
            for param in each.value.helm.parameters : {
              name  = param.name
              value = param.value
            }
          ] : null
        } : null
      }
      destination = {
        server    = try(each.value.destination.server, "https://kubernetes.default.svc")
        namespace = try(each.value.destination.namespace, "default")
      }
      syncPolicy = try(each.value.sync_policy, null) != null ? {
        automated = try(each.value.sync_policy.automated, null) != null ? {
          prune    = try(each.value.sync_policy.automated.prune, false)
          selfHeal = try(each.value.sync_policy.automated.self_heal, false)
        } : null
        syncOptions = try(each.value.sync_policy.sync_options, null)
        retry = try(each.value.sync_policy.retry, null) != null ? {
          limit = try(each.value.sync_policy.retry.limit, 5)
          backoff = {
            duration    = try(each.value.sync_policy.retry.backoff.duration, "5s")
            factor      = try(each.value.sync_policy.retry.backoff.factor, 2)
            maxDuration = try(each.value.sync_policy.retry.backoff.max_duration, "3m")
          }
        } : null
      } : null
    }
  })

  depends_on = [
    helm_release.argocd,
    time_sleep.wait_for_argocd_crds,
    kubectl_manifest.argocd_project,
    kubectl_manifest.argocd_repository
  ]
}
