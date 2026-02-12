################################################################################
## ArgoCD Helm Release
################################################################################

resource "helm_release" "argocd" {
  count = var.argocd_config.enable ? 1 : 0

  name             = var.argocd_config.name
  namespace        = var.argocd_config.namespace
  create_namespace = var.argocd_config.create_namespace
  repository       = var.argocd_config.helm_repository
  chart            = var.argocd_config.chart
  version          = var.argocd_config.version
  timeout          = var.argocd_config.timeout
  wait             = var.argocd_config.wait
  atomic           = var.argocd_config.atomic
  cleanup_on_fail  = var.argocd_config.cleanup_on_fail
  values = concat(
    var.argocd_config.helm_release_values,
    var.ingress_config.enable && var.ingress_config.host != "" ? [
      yamlencode({
        server = {
          ingress = {
            enabled = true
            ingressClassName = var.ingress_config.ingress_class_name
            hostname = var.ingress_config.host
          }
        }
      })
    ] : []
  )

  set = concat(
    [
      for k, v in(var.ingress_config.enable ? local.ingress_annotations : {}) : {
        name  = "server.ingress.annotations.${replace(k, ".", "\\.")}"
        value = v
      }
    ],
    local.merged_set_values
  )

  ## Note: depends_on with count-conditional resources is safe in Terraform.
  ## When IRSA is disabled, these resources evaluate to empty tuples — no error.
  depends_on = [
    aws_iam_role.argocd_server,
    aws_iam_role.argocd_repo_server,
    aws_iam_role_policy_attachment.argocd_server,
    aws_iam_role_policy_attachment.argocd_repo_server,
    aws_iam_role_policy_attachment.repo_server_ecr,
    helm_release.alb_controller,
  ]
}

################################################################################
## ArgoCD Image Updater Helm Release
################################################################################

resource "helm_release" "argocd_image_updater" {
  count = var.image_updater_config.enable ? 1 : 0

  name             = "argocd-image-updater"
  namespace        = local.argocd_namespace
  create_namespace = false
  repository       = var.argocd_config.helm_repository
  chart            = var.image_updater_config.chart
  version          = var.image_updater_config.version
  timeout          = var.argocd_config.timeout
  wait             = var.argocd_config.wait
  values           = var.image_updater_config.helm_release_values

  depends_on = [
    helm_release.argocd,
  ]
}
