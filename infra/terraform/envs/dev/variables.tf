variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "reddy-ebooks"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "node_group_name" {
  type    = string
  default = "reddy-ebooks-node"
}

variable "node_instance_type" {
  type    = string
  default = "t3.small"
}
