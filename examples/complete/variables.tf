variable "namespace" {
  description = "Namespace for the resources."
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "domain_name" {
  description = "Domain name for ArgoCD ingress."
  type        = string
  default     = "arc-poc.link"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Project   = "arc"
    ManagedBy = "terraform"
  }
}
