# EKS learning-lab IAM roles

This branch changes the infrastructure to **reuse** these IAM roles:

- EKS cluster service role: `EKS-Cluster` (must trust `eks.amazonaws.com` and have `AmazonEKSClusterPolicy`).
- EKS managed node role: `Role-all-service` (must trust `ec2.amazonaws.com` and include worker-node, ECR image pulling and VPC CNI permissions).
- kubectl administrator: Terraform creates `buddu-ebooks-lab-admin` with EKS `AmazonEKSClusterAdminPolicy`. **Keep this separate from the managed node role**.

> Development-only lab: the existing broad node role is reused as requested. In production use a least-privilege node role and no root credentials.

## Local AWS profile, once

Your original `eks-lab` profile currently identifies as AWS account root. It does **not** match the EKS administrator role.

To keep using `aws eks update-kubeconfig --profile eks-lab` without entering `--role-arn` each time, configure a chained AWS CLI profile **once** after the new cluster and role exist:

1. Keep the existing underlying credentials but move them out of `eks-lab` into a different profile such as `eks-source`. **Never commit or paste credentials.**
2. Add these settings in `~/.aws/config`:

   ```ini
   [profile eks-lab]
   role_arn = arn:aws:iam::981625497990:role/buddu-ebooks-lab-admin
   source_profile = eks-source
   region = us-east-1
   ```

3. Run `aws sts get-caller-identity --profile eks-lab`. Its ARN must show `assumed-role/buddu-ebooks-lab-admin`.
4. Run `aws eks update-kubeconfig --name buddu-ebooks --region us-east-1 --profile eks-lab`, then `kubectl get nodes`.

Use a dedicated human IAM/SSO role instead of root as the source identity in future. The console session must assume the lab-admin role to access Kubernetes resources; the IAM role used by the EC2 node is unrelated.

## State and cleanup

This branch references pre-existing IAM roles through Terraform **data sources**; Terraform won't own or delete those roles. The old Terraform-created roles and attachments were previously in Terraform state. Review the plan before applying: it should show their removal only as resources Terraform owns, not deletion of `EKS-Cluster` or `Role-all-service`.

Apply this branch **only after the old EKS lab is fully destroyed**. Check that Terraform state and AWS have no remaining EKS cluster, managed node group, or EKS access entry before recreating.
