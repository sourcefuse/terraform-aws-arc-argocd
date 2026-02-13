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
