# EKS + ArgoCD Integration Example

This example demonstrates deploying an EKS cluster using the [SourceFuse ARC EKS module](https://registry.terraform.io/modules/sourcefuse/arc-eks/aws/latest) and installing ArgoCD on it.

## Architecture

- **EKS Cluster**: Managed Kubernetes cluster with OIDC provider enabled
- **Node Groups**: Configurable worker nodes for running workloads
- **ArgoCD**: GitOps continuous delivery tool installed via Helm
- **ALB Ingress**: Application Load Balancer for external access
- **ACM Certificate**: SSL/TLS certificate for HTTPS
- **Route53**: DNS record for ArgoCD UI

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.6.0
- Existing VPC with public and private subnets
- Route53 hosted zone (if using auto DNS creation)

## Usage

### 1. Create a `terraform.tfvars` file:

```hcl
namespace   = "myapp"
environment = "dev"
region      = "us-east-1"

# VPC Configuration
vpc_id             = "vpc-xxxxx"
private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]

# ArgoCD Configuration
argocd_hostname            = "argocd.example.com"
route53_zone_name          = "example.com"
auto_create_route53_record = true
create_acm_certificate     = true

# Optional: High Availability
enable_ha = false

# Optional: Image Updater
enable_image_updater = false

tags = {
  Project     = "myapp"
  Environment = "dev"
  ManagedBy   = "terraform"
}
```

### 2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

### 3. Access ArgoCD:

After deployment completes (typically 10-15 minutes):

```bash
# Get the ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access the UI
# URL will be output as: argocd_server_url
```

## What Gets Created

### EKS Resources
- EKS Cluster with OIDC provider
- Managed node groups
- Cluster security groups
- IAM roles for nodes

### ArgoCD Resources
- ArgoCD Helm release (server, repo-server, application-controller)
- AWS Load Balancer Controller
- Application Load Balancer (ALB)
- ACM Certificate (if `create_acm_certificate = true`)
- Route53 DNS record (if `auto_create_route53_record = true`)
- IAM roles for IRSA (ArgoCD server and repo-server)

## Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_version` | Kubernetes version | `1.28` |
| `enable_ha` | Enable ArgoCD HA mode | `false` |
| `enable_image_updater` | Enable ArgoCD Image Updater | `false` |
| `create_acm_certificate` | Create new ACM certificate | `true` |
| `acm_certificate_arn` | Use existing certificate ARN | `""` |

## Cleanup

```bash
terraform destroy
```

**Note**: The destroy process may take 10-15 minutes as it needs to delete the ALB, EKS cluster, and associated resources.

## Troubleshooting

### ArgoCD UI not accessible

1. Check ALB is provisioned:
   ```bash
   kubectl get ingress -n argocd
   ```

2. Verify DNS resolution:
   ```bash
   dig argocd.example.com
   ```

3. Check ArgoCD pods are running:
   ```bash
   kubectl get pods -n argocd
   ```

### Certificate validation pending

If using `create_acm_certificate = true`, the certificate validation can take 5-10 minutes. Check status:

```bash
aws acm describe-certificate --certificate-arn <arn>
```

## Next Steps

After deployment:

1. **Configure SSO**: Add SSO configuration to `argocd_config`
2. **Add Applications**: Create ArgoCD Application resources
3. **Enable Notifications**: Configure ArgoCD notifications
4. **Set up RBAC**: Configure role-based access control

## Example with Existing Certificate

```hcl
create_acm_certificate = false
acm_certificate_arn    = "arn:aws:acm:us-east-1:123456789:certificate/xxxxx"
```

## Example with High Availability

```hcl
enable_ha = true
```

This will deploy:
- 2 ArgoCD server replicas
- 2 repo-server replicas
- Redis HA with sentinel

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.12.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.24.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.12.1 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd"></a> [argocd](#module\_argocd) | ../../ | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | sourcefuse/arc-eks/aws | 6.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.alb_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.alb_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.alb_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.alb_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [time_sleep.wait_for_cluster](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [http_http.alb_controller_iam_policy](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | Existing ACM certificate ARN (if not creating new). | `string` | `""` | no |
| <a name="input_argocd_hostname"></a> [argocd\_hostname](#input\_argocd\_hostname) | Hostname for ArgoCD UI (e.g., argocd.example.com). | `string` | `"argocd-poc2.arc-poc.link"` | no |
| <a name="input_auto_create_route53_record"></a> [auto\_create\_route53\_record](#input\_auto\_create\_route53\_record) | Automatically create Route53 A record for ArgoCD. | `bool` | `true` | no |
| <a name="input_create_acm_certificate"></a> [create\_acm\_certificate](#input\_create\_acm\_certificate) | Create new ACM certificate for ArgoCD. | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ArgoCD ingress. | `string` | `"arc-poc.link"` | no |
| <a name="input_enable_ha"></a> [enable\_ha](#input\_enable\_ha) | Enable high availability mode for ArgoCD. | `bool` | `false` | no |
| <a name="input_enable_image_updater"></a> [enable\_image\_updater](#input\_enable\_image\_updater) | Enable ArgoCD Image Updater. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. | `string` | `"dev"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for the resources. | `string` | `"arc"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | <pre>{<br/>  "ManagedBy": "terraform",<br/>  "Project": "arc"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | ACM certificate ARN used for ArgoCD ingress. |
| <a name="output_argocd_namespace"></a> [argocd\_namespace](#output\_argocd\_namespace) | Kubernetes namespace where ArgoCD is installed. |
| <a name="output_argocd_repo_server_iam_role_arn"></a> [argocd\_repo\_server\_iam\_role\_arn](#output\_argocd\_repo\_server\_iam\_role\_arn) | IAM role ARN for ArgoCD repo-server. |
| <a name="output_argocd_server_iam_role_arn"></a> [argocd\_server\_iam\_role\_arn](#output\_argocd\_server\_iam\_role\_arn) | IAM role ARN for ArgoCD server. |
| <a name="output_argocd_server_url"></a> [argocd\_server\_url](#output\_argocd\_server\_url) | URL to access ArgoCD UI. |
| <a name="output_argocd_status"></a> [argocd\_status](#output\_argocd\_status) | Status of the ArgoCD Helm release. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS cluster API server. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the EKS cluster. |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ID attached to the EKS cluster. |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | OIDC provider URL for the EKS cluster. |
| <a name="output_route53_record_fqdn"></a> [route53\_record\_fqdn](#output\_route53\_record\_fqdn) | FQDN of the Route53 record for ArgoCD. |
<!-- END_TF_DOCS -->
