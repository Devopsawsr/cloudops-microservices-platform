# EKS Dev lab — reliable kubectl and AWS Console access

This is a **temporary, low-cost learning lab**, not a production IAM design. The Terraform environment is `infra/terraform/envs/dev`.

## IAM roles and cluster

- **EKS cluster:** `reddy-ebooks` in `us-east-1` (AWS account `981625497990`).
- **EKS control-plane service role:** existing IAM role `EKS-Cluster`; used by EKS itself, **not** by kubectl.
- **Managed EC2 worker role:** Terraform-managed `reddy-ebooks-node-role`; worker permissions only, **not** Kubernetes cluster admin.
- **Terraform GitHub Actions role:** the value of the GitHub `aws-dev` environment secret `AWS_TERRAFORM_ROLE_ARN`. This may also receive initial bootstrap access as cluster creator, but it is not the intended local kubectl identity.
- **Human lab administrator role:** Terraform-managed `reddy-ebooks-lab-admin`, with a STANDARD EKS access entry and `AmazonEKSClusterAdminPolicy`, cluster-scoped. This is the identity to assume for kubectl and Kubernetes console access.

Terraform deliberately does **not** depend on an arbitrary IAM user named `eks-lab-user` existing. Create and authorize additional user/SSO roles explicitly if required.

## Before starting a new cluster

1. Ensure the old lab is fully destroyed through the Terraform workflow and that no old EKS resources remain in Terraform state.
2. From the repository's `main` branch after this change is merged, launch the existing Terraform workflow: environment **dev**, action **apply**. Wait for the full Terraform apply and verify stages to pass, including access-entry and policy-association creation.
3. The access entry is created by Terraform. **Do not** create it manually in the EKS Console while Terraform owns it.
4. EKS access-entry permissions can take a short time to propagate after Apply succeeds.

## Check that the new cluster allows the lab administrator

Use your existing AWS profile for *read-only checks*:

```bash
aws sts get-caller-identity --profile eks-lab
aws eks describe-cluster --name reddy-ebooks --region us-east-1 --profile eks-lab \
  --query 'cluster.accessConfig' --output json
aws eks list-access-entries --cluster-name reddy-ebooks --region us-east-1 --profile eks-lab
aws eks list-associated-access-policies \
  --cluster-name reddy-ebooks \
  --principal-arn arn:aws:iam::981625497990:role/reddy-ebooks-lab-admin \
  --region us-east-1 --profile eks-lab
```

Expected principal: `arn:aws:iam::981625497990:role/reddy-ebooks-lab-admin`, associated with `AmazonEKSClusterAdminPolicy`.

## kubectl — one-time kubeconfig and each new cluster rebuild

Your old `eks-lab` profile was identified by AWS STS as **root** (`arn:aws:iam::981625497990:root`). Root is not the role authorized by the EKS access entry. The lab role trust temporarily allows **only the account root principal** to assume the administrator role, so you must use the role for Kubernetes authentication:

```bash
export AWS_PROFILE=eks-lab
export AWS_DEFAULT_REGION=us-east-1
aws sts assume-role \
  --role-arn arn:aws:iam::981625497990:role/reddy-ebooks-lab-admin \
  --role-session-name verify-eks-admin \
  --profile eks-lab --query 'AssumedRoleUser.Arn' --output text
```

The last command should show an `assumed-role/reddy-ebooks-lab-admin/...` ARN. The command does **not** change your profile or save credentials. Never paste credentials or token JSON into a chat, file or repository.

Set kubeconfig to use this administrator role automatically at every kubectl authentication request:

```bash
aws eks update-kubeconfig \
  --name reddy-ebooks \
  --region us-east-1 \
  --profile eks-lab \
  --role-arn arn:aws:iam::981625497990:role/reddy-ebooks-lab-admin

kubectl config current-context
kubectl get nodes
```

The profile used by kubectl's exec authentication must be able to assume this role (and have permission to describe the cluster when building kubeconfig). You can also get the exact command after Terraform Apply:

```bash
cd infra/terraform/envs/dev
terraform output -raw kubectl_command
```

Do not run `kubectl apply -k` until `kubectl get nodes` works. Skipping OpenAPI validation does not fix authentication.

### Kubernetes access inside the AWS Console

The EKS Console uses the **IAM principal currently signed in**, not the role specified in your local kubeconfig. On the AWS Console role-switcher, switch to the IAM role `reddy-ebooks-lab-admin` in account `981625497990` if your session is allowed to assume it. Then open EKS → `reddy-ebooks` → Compute. Otherwise the Console can display `Unauthorized` even though the node group is `Active`. Console switching behavior depends on how the AWS session was established.

## Production improvements

Never use AWS root for routine CLI or console operations. Replace the lab-only root trust with IAM Identity Center (SSO) or a dedicated federated administrator role using temporary credentials and MFA. Define **named**, least-privilege access entries for each operator; reserve cluster-admin for administrators. Worker nodes must never receive the human administrator access entry.

Deleting and recreating EKS does not inherently solve IAM mismatches. The access entry and policy association must be recreated **and** the correct role must be used by kubectl and the Console.
