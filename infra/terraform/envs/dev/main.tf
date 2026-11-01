# Development-only EKS cluster: reuse default VPC and its public subnets.
# No VPC, NAT gateway, ALB or application workloads are created.
data "aws_vpc" "default" {
  default = true
}

# Explicitly select two EKS-supported AZs. Do not pass all VPC subnets.
# us-east-1e is unsupported for EKS control-plane placement in this account.
data "aws_subnets" "zone_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

data "aws_subnets" "zone_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

locals {
  # The default VPC normally has exactly one public subnet per AZ.
  # one() fails safely if an AZ has zero or multiple matching subnets.
  eks_subnet_ids = [
    one(data.aws_subnets.zone_a.ids),
    one(data.aws_subnets.zone_b.ids),
  ]
}

# Reuse the existing EKS control-plane role. The worker role is separate,
# created in node-iam.tf and managed by Terraform.
data "aws_iam_role" "cluster" {
  name = "EKS-Cluster"
}

resource "aws_eks_cluster" "lab" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  # EKS Auto Mode is explicitly OFF; nodes use the managed node group below.
  compute_config {
    enabled = false
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = local.eks_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  lifecycle {
    precondition {
      condition     = alltrue([for id in local.eks_subnet_ids : id != null])
      error_message = "Missing public subnet in us-east-1a or us-east-1b of the default VPC."
    }
  }
}

resource "aws_eks_node_group" "lab" {
  cluster_name    = aws_eks_cluster.lab.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.eks_subnet_ids

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker,
    aws_iam_role_policy_attachment.ecr,
    aws_iam_role_policy_attachment.cni,
  ]
}
