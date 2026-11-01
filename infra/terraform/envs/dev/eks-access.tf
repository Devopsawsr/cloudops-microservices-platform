# The EC2 node role (Role-all-service) must not also have a STANDARD
# administrator access entry: EKS manages node-role authentication itself.
#
# For this temporary learning lab, provide a separate IAM role for kubectl
# and AWS Console access. The trust is restricted to the account root principal.
# Replace root access with an SSO/admin identity for non-lab usage.
data "aws_iam_policy_document" "lab_admin_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::981625497990:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::981625497990:root"]
    }
  }
}

resource "aws_iam_role" "lab_admin" {
  name               = "${var.cluster_name}-lab-admin"
  assume_role_policy = data.aws_iam_policy_document.lab_admin_assume.json
}

resource "aws_eks_access_entry" "lab_operator" {
  cluster_name  = aws_eks_cluster.lab.name
  principal_arn = aws_iam_role.lab_admin.arn
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


# Persistent access for the local AWS CLI profile "eks-lab-user".
# This IAM user exists independently of the EKS cluster, while its EKS
# access entry will be created on apply and removed on destroy.
resource "aws_eks_access_entry" "local_cli_user" {
  cluster_name  = aws_eks_cluster.lab.name
  principal_arn = "arn:aws:iam::981625497990:user/eks-lab-user"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "local_cli_user" {
  cluster_name  = aws_eks_cluster.lab.name
  principal_arn = aws_eks_access_entry.local_cli_user.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
