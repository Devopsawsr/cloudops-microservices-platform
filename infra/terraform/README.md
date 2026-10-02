# Platform (AWS)

Same as a real org: **app Git** is this repo. **Cluster / ECR / RDS** are platform.

```text
infra/terraform/
  envs/dev
  envs/qa
  envs/production
```

Each environment will own EKS configuration, 11 ECR repositories, RDS connectivity, node IAM and IRSA roles.

Terraform implementation follows successful kubeadm validation. Do not run `terraform apply` until the modules, remote state, variables, security controls and plan output have been reviewed.
