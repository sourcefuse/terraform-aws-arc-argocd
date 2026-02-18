################################################################################
## IRSA Trust Policy
################################################################################

data "aws_iam_policy_document" "argocd_assume_role" {
  count = var.irsa_config.enable ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

################################################################################
## ArgoCD Server IRSA Role
################################################################################

resource "aws_iam_role" "argocd_server" {
  count = var.irsa_config.enable ? 1 : 0

  name               = local.irsa_server_role_name
  assume_role_policy = data.aws_iam_policy_document.argocd_assume_role[0].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "argocd_server" {
  for_each = var.irsa_config.enable ? toset(var.irsa_config.server_policy_arns) : toset([])

  role       = aws_iam_role.argocd_server[0].name
  policy_arn = each.value
}

################################################################################
## ArgoCD Repo Server IRSA Role
################################################################################

resource "aws_iam_role" "argocd_repo_server" {
  count = var.irsa_config.enable ? 1 : 0

  name               = local.irsa_repo_server_role_name
  assume_role_policy = data.aws_iam_policy_document.argocd_assume_role[0].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "argocd_repo_server" {
  for_each = var.irsa_config.enable ? toset(var.irsa_config.repo_server_policy_arns) : toset([])

  role       = aws_iam_role.argocd_repo_server[0].name
  policy_arn = each.value
}

################################################################################
## ECR Read-Only Policy for Repo Server (Helm charts from ECR)
################################################################################

data "aws_iam_policy_document" "ecr_readonly" {
  count = var.irsa_config.enable ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_readonly" {
  count = var.irsa_config.enable ? 1 : 0

  name   = "${local.name}-ecr-readonly"
  policy = data.aws_iam_policy_document.ecr_readonly[0].json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "repo_server_ecr" {
  count = var.irsa_config.enable ? 1 : 0

  role       = aws_iam_role.argocd_repo_server[0].name
  policy_arn = aws_iam_policy.ecr_readonly[0].arn
}
