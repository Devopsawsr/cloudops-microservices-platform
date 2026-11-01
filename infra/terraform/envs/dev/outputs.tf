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
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.lab.name}"
}
