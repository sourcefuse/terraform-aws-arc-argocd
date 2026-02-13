# Complete ArgoCD Deployment Example

This example demonstrates a complete ArgoCD deployment on an existing EKS cluster with all production-ready features enabled.

## Overview

This example showcases:

- ArgoCD installation on an existing EKS cluster
- AWS Load Balancer Controller integration
- ACM certificate creation with DNS validation
- Route53 DNS record automation
- IRSA (IAM Roles for Service Accounts) configuration
- Production-ready ingress configuration

## Prerequisites

Before running this example, ensure you have:

1. **Existing EKS Cluster**: A running EKS cluster with OIDC provider enabled
2. **AWS Credentials**: Configured with appropriate permissions
3. **Terraform**: Version >= 1.6.0 installed
4. **kubectl**: Configured to access your EKS cluster
5. **Route53 Hosted Zone**: A public hosted zone for your domain
6. **VPC Configuration**: Public subnets for ALB deployment

## Required AWS Permissions

The AWS credentials used must have permissions to create:

- IAM roles and policies
- ACM certificates
- Route53 records
- Kubernetes resources (via EKS)
- Application Load Balancers

## Quick Start

### 1. Configure Variables

Create a `terraform.tfvars` file:

```hcl
namespace   = "myapp"
environment = "prod"
region      = "us-east-1"

# EKS Cluster Configuration
eks_cluster_name = "my-production-cluster"

# Domain Configuration
domain_name = "example.com"

# Tags
tags = {
  Project     = "myapp"
  Environment = "prod"
  ManagedBy   = "terraform"
  Team        = "platform"
}
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply Configuration

```bash
terraform apply
```

The deployment typically takes 5-10 minutes.

## What Gets Created

### AWS Resources

1. **IAM Roles**
   - ArgoCD Server IRSA role
   - ArgoCD Repo-Server IRSA role with ECR read access
   - ALB Controller IRSA role

2. **ACM Certificate**
   - SSL/TLS certificate for `argocd.example.com`
   - DNS validation records in Route53

3. **Route53 Records**
   - A record pointing to ALB
   - DNS validation records for ACM

4. **Application Load Balancer**
   - Internet-facing ALB
   - HTTPS listener on port 443
   - HTTP to HTTPS redirect

### Kubernetes Resources

1. **ArgoCD Components**
   - ArgoCD Server
   - Repository Server
   - Application Controller
   - Redis cache
   - Dex (SSO) - optional

2. **AWS Load Balancer Controller**
   - Helm release
   - Service account with IRSA

3. **Ingress Resource**
   - ALB ingress for ArgoCD UI
   - TLS termination configuration

## Accessing ArgoCD

### Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Access the UI

The ArgoCD UI will be available at: `https://argocd.example.com`

Login with:
- Username: `admin`
- Password: (from command above)

### CLI Access

```bash
# Install ArgoCD CLI
brew install argocd  # macOS
# or download from https://github.com/argoproj/argo-cd/releases

# Login
argocd login argocd.example.com

# List applications
argocd app list
```

## Configuration Options

### Enable High Availability

Modify `main.tf`:

```hcl
ha_config = {
  enable               = true
  server_replicas      = 3
  repo_server_replicas = 2
  controller_replicas  = 1
}
```

### Enable Image Updater

```hcl
image_updater_config = {
  enable = true
}
```

### Use Existing Certificate

```hcl
ingress_config = {
  enable                     = true
  host                       = "argocd.example.com"
  create_acm_certificate     = false
  acm_certificate_arn        = "arn:aws:acm:us-east-1:123456789:certificate/xxxxx"
  install_alb_controller     = true
  auto_create_route53_record = true
  route53_zone_name          = "example.com"
  alb_subnets                = ["subnet-xxxxx", "subnet-yyyyy"]
}
```

### Custom ALB Annotations

```hcl
ingress_config = {
  # ... other config ...
  annotations = {
    "alb.ingress.kubernetes.io/group.name"                = "shared-alb"
    "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=300"
    "alb.ingress.kubernetes.io/wafv2-acl-arn"            = "arn:aws:wafv2:..."
  }
}
```

## Outputs

After successful deployment, the following outputs are available:

```bash
terraform output argocd_server_url        # ArgoCD UI URL
terraform output argocd_status            # Deployment status
terraform output server_iam_role_arn      # IRSA role ARN
```

## Customization

### Custom Helm Values

Add custom ArgoCD configuration:

```hcl
argocd_config = {
  enable  = true
  version = "7.8.13"

  helm_release_values = [
    yamlencode({
      configs = {
        cm = {
          "timeout.reconciliation" = "180s"
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
        }
      }
    })
  ]
}
```

### Additional IRSA Policies

Attach custom policies to ArgoCD roles:

```hcl
irsa_config = {
  enable = true
  server_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
  repo_server_policy_arns = [
    "arn:aws:iam::123456789:policy/CustomECRPolicy"
  ]
}
```

## Troubleshooting

### ArgoCD UI Returns 504 Gateway Timeout

**Cause**: ALB cannot reach ArgoCD pods.

**Solution**:
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ingress
kubectl describe ingress -n argocd

# Verify security groups allow traffic from ALB to pods
```

### Certificate Validation Stuck

**Cause**: DNS validation records not propagated.

**Solution**:
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn <arn>

# Verify DNS records
dig _validation.argocd.example.com

# Wait 5-10 minutes for DNS propagation
```

### ALB Not Created

**Cause**: Subnet tags missing or ALB controller not running.

**Solution**:
```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify subnet tags
aws ec2 describe-subnets --subnet-ids subnet-xxxxx
# Should have: kubernetes.io/role/elb = 1
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: Ensure all ArgoCD applications are deleted before destroying the infrastructure to avoid orphaned resources.

## Cost Estimation

Approximate monthly costs (us-east-1):

- **Application Load Balancer**: ~$16-25/month
- **Route53 Hosted Zone**: $0.50/month
- **ACM Certificate**: Free
- **EKS Control Plane**: $73/month (existing cluster)
- **Data Transfer**: Variable based on usage

**Total Additional Cost**: ~$17-26/month (excluding EKS and data transfer)

## Security Best Practices

1. **Enable IRSA**: Always use IAM roles for service accounts
2. **Use HTTPS**: Enforce TLS termination at ALB
3. **Restrict Access**: Use security groups and NACLs
4. **Enable SSO**: Configure Dex for enterprise authentication
5. **Rotate Credentials**: Change admin password after initial setup
6. **Enable Audit Logs**: Configure ArgoCD audit logging
7. **Network Segmentation**: Deploy ArgoCD in private subnets

## Next Steps

After deployment:

1. **Configure SSO**: Set up GitHub/OIDC/SAML authentication
2. **Create Applications**: Deploy your first ArgoCD application
3. **Set up RBAC**: Configure role-based access control
4. **Enable Notifications**: Configure Slack/email notifications
5. **Backup Configuration**: Export ArgoCD configuration regularly

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Module Documentation](../../README.md)

## Support

For issues or questions:

- [GitHub Issues](https://github.com/sourcefuse/terraform-aws-arc-argocd/issues)
- [SourceFuse Support](https://www.sourcefuse.com)
