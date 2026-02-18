################################################################################
## EKS Cluster Module
################################################################################

module "eks" {
  source  = "sourcefuse/arc-eks/aws"
  version = "6.0.1"

  namespace                             = var.namespace
  environment                           = var.environment
  name                                  = "${var.namespace}-${var.environment}-eks"
  kubernetes_version                    = "1.32"
  bootstrap_self_managed_addons_enabled = false

  vpc_config = {
    subnet_ids              = data.aws_subnets.private.ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  access_config = {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enable_oidc_provider = true

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  envelope_encryption = {
    enable = false
  }

  auto_mode_config = {
    enable     = true
    node_pools = ["general-purpose", "system"]
  }

  tags = var.tags
}

################################################################################
## Wait for EKS Cluster to be Ready
################################################################################

resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]

  create_duration = "120s"
}

################################################################################
## ALB Controller IAM Policy
################################################################################

data "http" "alb_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.namespace}-${var.environment}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_controller_iam_policy.response_body

  tags = var.tags
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.namespace}-${var.environment}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

################################################################################
## ALB Controller Helm Release
################################################################################

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.10.2"

  set {
    name  = "clusterName"
    value = module.eks.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.this.id
  }

  depends_on = [
    module.eks,
    time_sleep.wait_for_cluster,
    aws_iam_role_policy_attachment.alb_controller
  ]
}

################################################################################
## ArgoCD Module
################################################################################

module "argocd" {
  source = "../../"

  namespace   = var.namespace
  environment = var.environment

  eks_cluster_name = module.eks.name

  argocd_config = {
    enable  = true
    version = "7.8.13"

    helm_release_set_values = [
      {
        name  = "configs.cm.url"
        value = "https://${var.argocd_hostname}"
      },
      {
        name  = "configs.params.server\\.insecure"
        value = "true"
      }
    ]
  }

  ha_config = {
    enable = var.enable_ha
  }

  ingress_config = {
    enable                     = true
    host                       = var.argocd_hostname
    ingress_class_name         = "alb"
    create_acm_certificate     = var.create_acm_certificate
    acm_certificate_arn        = var.acm_certificate_arn
    auto_create_route53_record = var.auto_create_route53_record
    route53_zone_name          = var.domain_name
    alb_subnets                = data.aws_subnets.public.ids
    annotations = {
      "alb.ingress.kubernetes.io/group.name" = "${var.namespace}-${var.environment}"
    }
  }

  irsa_config = {
    enable = true
  }

  image_updater_config = {
    enable = var.enable_image_updater
  }

  tags = var.tags

  depends_on = [module.eks, time_sleep.wait_for_cluster, helm_release.alb_controller]
}
