################################################################################
## ALB Controller Installation
################################################################################

locals {
  # Install ALB controller only if explicitly enabled by user
  install_alb_controller = var.ingress_config.enable && var.ingress_config.install_alb_controller
}

################################################################################
## ALB Controller IAM Role
################################################################################

data "http" "alb_controller_iam_policy" {
  count = local.install_alb_controller ? 1 : 0
  url   = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  count = local.install_alb_controller ? 1 : 0

  name   = "${local.name}-alb-controller"
  policy = data.http.alb_controller_iam_policy[0].response_body
  tags   = local.common_tags
}

resource "aws_iam_role" "alb_controller" {
  count = local.install_alb_controller ? 1 : 0

  name               = "${local.name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role[0].json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "alb_controller_assume_role" {
  count = local.install_alb_controller ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  count = local.install_alb_controller ? 1 : 0

  role       = aws_iam_role.alb_controller[0].name
  policy_arn = aws_iam_policy.alb_controller[0].arn
}

################################################################################
## Install ALB Controller via Helm
################################################################################

resource "helm_release" "alb_controller" {
  count = local.install_alb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"

  values = [
    yamlencode({
      clusterName = var.eks_cluster_name
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller[0].arn
        }
      }
      vpcId = var.vpc_id != "" ? var.vpc_id : null
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.alb_controller
  ]
}
