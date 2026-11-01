# Standard networking add-ons for the non-Auto-Mode EKS lab.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.lab.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"

}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.lab.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.lab.name
  addon_name   = "coredns"

  # CoreDNS pods need worker capacity to become healthy.
  depends_on = [aws_eks_node_group.lab]
}
