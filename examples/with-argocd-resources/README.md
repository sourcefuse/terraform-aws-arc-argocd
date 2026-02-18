# ArgoCD with Resources Example

This example demonstrates how to deploy ArgoCD with repositories, projects, and applications.

## Features Demonstrated

- ArgoCD installation on existing EKS cluster
- Helm repository configuration
- ArgoCD project creation
- ArgoCD application deployment with Helm chart

## Prerequisites

- Existing EKS cluster
- kubectl configured to access the cluster
- Terraform >= 1.6.0

## Usage

1. Update `terraform.tfvars` with your EKS cluster name:

```hcl
eks_cluster_name = "your-eks-cluster-name"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

3. Access ArgoCD:

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

4. Open browser to `https://localhost:8080` and login with:
   - Username: `admin`
   - Password: (from step 3)

## What Gets Created

- **Repositories**:
  - nginx-helm-repo (Ingress NGINX Helm charts)
  - bitnami-helm-repo (Bitnami Helm charts)

- **Projects**:
  - demo-project (allows all sources and destinations)

- **Applications**:
  - nginx-ingress (NGINX Ingress Controller deployed via Helm)

## Cleanup

```bash
terraform destroy
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.12.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.24.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.32.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd"></a> [argocd](#module\_argocd) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ArgoCD ingress. | `string` | `"arc-poc.link"` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. | `string` | `"dev"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for the resources. | `string` | `"arc"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | <pre>{<br/>  "ManagedBy": "terraform",<br/>  "Project": "arc"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_applications"></a> [applications](#output\_applications) | Created ArgoCD applications |
| <a name="output_argocd_server_url"></a> [argocd\_server\_url](#output\_argocd\_server\_url) | ArgoCD server URL |
| <a name="output_projects"></a> [projects](#output\_projects) | Created ArgoCD projects |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | Created ArgoCD repositories |
<!-- END_TF_DOCS -->
