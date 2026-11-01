# IAM OIDC identity provider follows each newly-created EKS cluster issuer.
# IRSA is scoped to the aws-load-balancer-controller Kubernetes ServiceAccount.
locals {
  lbc_oidc_issuer   = aws_eks_cluster.lab.identity[0].oidc[0].issuer
  lbc_oidc_hostpath = trimprefix(local.lbc_oidc_issuer, "https://")
}

resource "aws_iam_openid_connect_provider" "eks" {
  url            = local.lbc_oidc_issuer
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "lbc_assume" {
  statement {
    sid     = "AllowLBCServiceAccount"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.lbc_oidc_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.lbc_oidc_hostpath}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  name               = "${var.cluster_name}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume.json
}

# Version-pinned upstream controller policy; committed to this repository.
resource "aws_iam_policy" "lbc" {
  name   = "${var.cluster_name}-aws-load-balancer-controller"
  policy = file("${path.module}/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}
