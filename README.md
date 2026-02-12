![Module Structure](./static/banner.png)
# AWS Terraform Module
# [terraform-aws-arc-argocd](https://github.com/sourcefuse/terraform-aws-arc-argocd)

<a href="https://github.com/sourcefuse/terraform-aws-arc-argocd/releases/latest"><img src="https://img.shields.io/github/release/sourcefuse/terraform-aws-arc-argocd.svg?style=for-the-badge" alt="Latest Release"/></a> <a href="https://github.com/sourcefuse/terraform-aws-arc-argocd/commits"><img src="https://img.shields.io/github/last-commit/sourcefuse/terraform-aws-arc-argocd.svg?style=for-the-badge" alt="Last Updated"/></a> ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

[![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=sourcefuse_terraform-aws-arc-argocd&token=13a2f3a3c3de5bc9caf8060148954bd0979ceab4)](https://sonarcloud.io/summary/new_code?id=sourcefuse_terraform-aws-arc-argocd)

---

# terraform-aws-arc-argocd

## Overview

SourceFuse AWS Reference Architecture (ARC) Terraform module for managing **ArgoCD** on Amazon EKS clusters.

This module installs and configures ArgoCD, a declarative, GitOps continuous delivery tool for Kubernetes. It provides comprehensive support for:

- **ArgoCD Core**: Main ArgoCD installation with configurable high availability
- **AWS Load Balancer Controller**: Optional ALB installation for ingress management
- **ACM Certificate Management**: Automatic certificate creation or use of existing certificates
- **Route53 Integration**: Automated DNS record creation for external access
- **IAM Roles for Service Accounts (IRSA)**: Secure AWS integration
- **ArgoCD Image Updater**: Automated container image updates
- **ApplicationSet Controller**: Multi-cluster and monorepo support
- **SSO Integration**: Dex authentication support for enterprise SSO
- **Notifications Controller**: Event-driven notifications for ArgoCD workflows

## Usage

To see a full example, check out the [main.tf](./examples/complete/main.tf) file in the examples folder.

### Basic Example

```hcl
module "argocd" {
  source = "git::https://github.com/sourcefuse/terraform-aws-arc-argocd"

  namespace   = "arc"
  environment = "prod"

  eks_cluster_name      = "my-eks-cluster"
  eks_cluster_endpoint  = "https://XXX.gr7.us-east-1.eks.amazonaws.com"
  eks_oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/XXX"
  eks_oidc_provider_arn = "arn:aws:iam::XXX:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/XXX"

  argocd_config = {
    enable  = true
    version = "7.8.13"
  }

  ingress_config = {
    enable                     = true
    host                       = "argocd.example.com"
    ingress_class_name         = "alb"
    auto_create_route53_record = true
    route53_zone_name          = "example.com"
  }

  alb_controller_config = {
    enable             = true
    helm_chart_version  = "1.7.1"
    iam_policy_version   = "v2.7.1"
  }

  acm_certificate_config = {
    create_certificate  = true
    certificate_domain = "argocd.example.com"
    validation_method = "DNS"
  }

  irsa_config = {
    enable = true
  }

  tags = {
    Project   = "arc"
    ManagedBy = "terraform"
  }
}
```

### Key Features

#### 1. **Conditional ALB Controller Installation**
The module no longer automatically installs the AWS Load Balancer Controller. You must explicitly enable it:

```hcl
alb_controller_config = {
  enable = true  # Must be explicitly set to true
}
```

This provides better control over your cluster's ingress infrastructure.

#### 2. **Automatic ACM Certificate Creation**
The module can automatically create and validate ACM certificates for HTTPS:

```hcl
acm_certificate_config = {
  create_certificate = true  # Create new certificate
  certificate_domain  = "argocd.example.com"
  validation_method  = "DNS"
}
```

Or use an existing certificate:

```hcl
ingress_config = {
  acm_certificate_arn = "arn:aws:acm:us-east-1:XXX:certificate/XXX"
}
```

#### 3. **Complete ArgoCD Ecosystem**
- **Core ArgoCD**: GitOps-based deployment automation
- **Image Updater**: Automatic image tag updates
- **ApplicationSet**: Multi-cluster deployment support
- **Notifications**: Integration with Slack, email, webhooks
- **SSO**: Dex-based authentication (GitHub, OIDC, SAML)



### Configuration Scenarios

#### Scenario 1: Minimal ArgoCD (No Ingress)
```hcl
module "argocd" {
  source = "sourcefuse/arc-argocd/aws"

  argocd_config = {
    enable = true
  }

  irsa_config = {
    enable = false  # No AWS integration needed
  }
}
```

#### Scenario 2: Full HTTPS with Existing Certificate
```hcl
ingress_config = {
  enable              = true
  host                = "argocd.example.com"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456:certificate/abc123"

  alb_controller_config = {
    enable = true  # Explicitly enable ALB controller
  }
}
```

#### Scenario 3: Automatic Certificate Creation
```hcl
acm_certificate_config = {
  create_certificate = true
  certificate_domain  = "argocd.example.com"
  validation_method  = "DNS"
}
```

### Troubleshooting

#### Common Issues

**1. ArgoCD UI not accessible**
- Verify ALB controller is enabled: `alb_controller_config.enable = true`
- Check Route53 record creation: `ingress_config.auto_create_route53_record = true`
- Ensure security groups allow HTTPS (port 443) from your IP

**2. Certificate validation fails**
- Verify Route53 hosted zone is in the same AWS account
- Check `validation_method` - use "DNS" for automatic validation
- Allow sufficient time for DNS propagation (typically 5-30 minutes)

**3. IRSA permissions errors**
- Verify OIDC provider is configured on EKS cluster
- Check IAM role policies include required permissions
- Ensure service account annotations match role ARNs

**4. Image Updater cannot access ECR**
- Enable IRSA for repo-server: `irsa_config.enable = true`
- Verify ECR policy is attached to repo-server role
- Check image registry credentials in Image Updater config

**5. High Availability not working**
- Enable HA mode: `ha_config.enable = true`
- Verify Redis HA is enabled (automatically configured with HA)
- Check replica counts: `ha_config.server_replicas = 2`

### Module Outputs

The module provides the following outputs:

- `argocd_server_url`: URL to access ArgoCD UI
- `namespace`: Kubernetes namespace where ArgoCD is installed
- `chart_version`: Deployed Helm chart version
- `status`: Helm release status
- `server_iam_role_arn`: IRSA role ARN for ArgoCD server
- `repo_server_iam_role_arn`: IRSA role ARN for repo-server
- `acm_certificate_arn`: ACM certificate ARN (created or provided)
- `route53_record_fqdn`: Route53 FQDN for external access
- `alb_dns_name`: ALB DNS name

### Dependencies

- **EKS Cluster**: Must exist with OIDC provider enabled
- **VPC**: Required for ALB and network resources
- **Route53**: Optional, for DNS record creation
- **ACM**: Optional, for HTTPS certificate management

### Upgrade Strategy

1. **Pre-upgrade checks**:
   - Backup ArgoCD configurations: `argocd-k8s-config`
   - Document custom Helm values
   - Note current chart version

2. **Upgrade process**:
   ```bash
   # Update version in Terraform configuration
   argocd_config = {
     version = "7.8.14"  # New version
   }

   # Apply changes
   terraform apply
   ```

3. **Post-upgrade**:
   - Verify all applications are syncing
   - Check ArgoCD UI accessibility
   - Monitor application sync status

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Versioning  
This project uses a `.version` file at the root of the repo which the pipeline reads from and does a git tag.  

When you intend to commit to `main`, you will need to increment this version. Once the project is merged,
the pipeline will kick off and tag the latest git commit.  

## Development

### Prerequisites

- [terraform](https://learn.hashicorp.com/terraform/getting-started/install#installing-terraform)
- [terraform-docs](https://github.com/segmentio/terraform-docs)
- [pre-commit](https://pre-commit.com/#install)
- [golang](https://golang.org/doc/install#install)
- [golint](https://github.com/golang/lint#installation)

### Configurations

- Configure pre-commit hooks
  ```sh
  pre-commit install
  ```

### Versioning

while Contributing or doing git commit please specify the breaking change in your commit message whether its major,minor or patch

For Example

```sh
git commit -m "your commit message #major"
```
By specifying this , it will bump the version and if you don't specify this in your commit message then by default it will consider patch and will bump that accordingly

### Tests
- Tests are available in `test` directory
- Configure the dependencies
  ```sh
  cd test/
  go mod init github.com/sourcefuse/terraform-aws-refarch-<module_name>
  go get github.com/gruntwork-io/terratest/modules/terraform
  ```
- Now execute the test  
  ```sh
  go test -timeout  30m
  ```

## Authors

This project is authored by:
- SourceFuse ARC Team
