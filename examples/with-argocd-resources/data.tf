################################################################################
## Data Sources
################################################################################

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["arc-poc-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}
