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
