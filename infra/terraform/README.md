# AWS EKS Terraform learning lab

This **small disposable dev lab** lives under [envs/dev](envs/dev). QA, Staging and production infrastructure remain unprovisioned; this is not the full microservices platform infrastructure.

## Lab configuration

- EKS cluster: `buddu-ebooks`, Kubernetes `1.34`, `us-east-1`
- **EKS Auto Mode disabled**
- Managed node group: `reddy-ebooks-node`, one On-Demand `t3.small` (min 1, max 2)
- Reuses default VPC and suitable public subnets; no new NAT gateway, VPC, or load balancer
- Creates dedicated cluster/node roles, plus standard EKS add-ons: VPC CNI, kube-proxy, CoreDNS
- Public EKS API endpoint for learning only (not production hardened)

## Prerequisites (one-time)

1. **S3 state bucket:** existing `reddy-buddu` in `us-east-1`. State object key is `cloudops/eks-lab/dev/terraform.tfstate` (separate from other Terraform projects). Enable S3 versioning, encryption and block public access.
2. **GitHub OIDC:** Create an IAM role that GitHub Actions can assume, scoped to this repository and the intended branch/environment. Give it permissions for EKS, IAM roles/policy attachments, `iam:PassRole`, VPC reads and S3 state access, including lock object permissions. No access keys needed in GitHub.
3. Configure GitHub Actions `aws-dev` environment secret `AWS_TERRAFORM_ROLE_ARN` with the OIDC role ARN.
4. Do **not** delete an existing EKS cluster to resolve a Terraform conflict. Inspect state and reconcile only verified, owned resources; the workflow includes a controlled IAM recovery action.

The state backend needs `s3:ListBucket` on `reddy-buddu`, `s3:GetObject` and `s3:PutObject` on the state key, and `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the matching `.tflock` object. Keep the S3 bucket after destroying the lab.

## GitHub Actions

Once the PR is merged, open **Actions → EKS Lab - Terraform → Run workflow**:

- `plan` previews resources
- `recover` attempts ownership-verified import of known IAM resources into remote state and previews a plan
- `apply` provisions or changes billable cluster and worker resources
- `destroy` removes Terraform-managed resources; enter `DESTROY` to confirm

All operations are manually triggered. Runs are serialized, and the same S3 state is shared between runs.

## Local CLI (same remote state)

```bash
cd infra/terraform/envs/dev
export AWS_PROFILE=eks-lab
terraform init \
  -backend-config="bucket=reddy-buddu" \
  -backend-config="key=cloudops/eks-lab/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform fmt
terraform validate
terraform plan
terraform plan # Review before choosing to apply changes
aws eks update-kubeconfig --name buddu-ebooks --region us-east-1 --profile eks-lab
kubectl get nodes
 # Destroy only when intentionally retiring the lab (billable resources)
```

Do not delete the state file or manage this same cluster with both eksctl and Terraform. Verify worker-node and add-on health after creation.

**Cost/security notes:** EKS/EC2 incur charges until destroyed. Check for independently created EBS volumes, public IPs, load balancers and NAT gateways after `destroy`. This public-subnet lab isn't production hardened. For production use private subnets, least-privilege EKS access entries, limited API endpoint access and an independent VPC CNI IAM role.
