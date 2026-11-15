output "cluster_name" {
  value = aws_eks_cluster.lab.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.lab.endpoint
}

output "node_group_name" {
  value = aws_eks_node_group.lab.node_group_name
}

output "kubectl_command" {
  description = "Generate a kubeconfig that authenticates through the dedicated lab administrator role."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.lab.name} --profile eks-lab --role-arn ${aws_iam_role.lab_admin.arn}"
}

output "lab_admin_role_arn" {
  description = "Assume this role for kubectl and Kubernetes resources in the EKS console."
  value       = aws_iam_role.lab_admin.arn
}

output "lab_admin_access_policy" {
  description = "Associated EKS administrator access policy. Terraform must finish applying this resource before kubectl access works."
  value       = aws_eks_access_policy_association.lab_operator.policy_arn
}

output "eks_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.lbc.arn
}
