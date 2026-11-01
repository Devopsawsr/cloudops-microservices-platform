# Access for the explicitly authorized lab administrator role.
# Not granted to EC2 worker nodes or to all IAM principals.
resource "aws_eks_access_entry" "lab_operator" {
  cluster_name  = aws_eks_cluster.lab.name
  principal_arn = "arn:aws:iam::981625497990:role/Role-all-service"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "lab_operator" {
  cluster_name  = aws_eks_cluster.lab.name
  principal_arn = aws_eks_access_entry.lab_operator.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
