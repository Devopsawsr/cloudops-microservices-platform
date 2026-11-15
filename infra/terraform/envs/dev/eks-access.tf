# EKS authentication for this temporary development lab.
# Managed node IAM roles are authenticated automatically by EKS; do not give
# the worker-node role a STANDARD administrator access entry.
#
# Keep kubectl administrator access separate from the GitHub Actions Terraform
# execution role and the EC2 worker role.
#
# LAB ONLY: the AWS account root principal is permitted to assume this
# dedicated admin role. Replace this trust with IAM Identity Center / a
# dedicated administrator identity before using this outside the lab.
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lab_admin_assume" {
  statement {
    sid     = "AllowLabRootToAssumeAdministratorRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "lab_admin" {
  name               = "${var.cluster_name}-lab-admin"
  assume_role_policy = data.aws_iam_policy_document.lab_admin_assume.json
  description        = "Temporary human kubectl admin role for the ${var.cluster_name} EKS lab"
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

# Avoid hard-coding a second (possibly nonexistent) IAM user access entry.
# To add more operators, create explicit, reviewed access entries for their
# existing IAM roles. An absent user principal can cause Terraform Apply to
# fail during every rebuild.
