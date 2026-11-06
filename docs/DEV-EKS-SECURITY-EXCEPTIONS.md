# Dev EKS — cost-conscious security exceptions

**Scope:** `infra/terraform/envs/dev/main.tf`, resource `aws_eks_cluster.lab` only. These are risk acceptances for a **temporary single-user learning environment**, not recommendations for QA, staging, or production. Review before sharing access, storing real secrets, or hosting real users.

The Checkov scanner stays enabled for all other resources and policies. These four checks were blocking the Dev Apply workflow on 6 November 2026; their resource-scoped exceptions document why the lab currently diverges from stricter security policies.

| Check | Exception | Risk / remediation |
|---|---|---|
| CKV_AWS_37 | EKS control-plane logging left disabled to avoid CloudWatch ingestion and storage costs. | Reduced audit and troubleshooting visibility; enable logs with retention and budgets when needed. |
| CKV_AWS_38 | The public API endpoint is not currently restricted to a fixed laptop IP. | Anyone on the internet can reach the API endpoint (but AWS/Kubernetes authorization still applies); restrict `public_access_cidrs` to current trusted IPv4 addresses before shared use. |
| CKV_AWS_39 | Public endpoint access needed for local `kubectl` from changing networks. | Additional attack surface; migrate to private-only API access with appropriate private connectivity for production. |
| CKV_AWS_58 | EKS 1.34 uses default AWS-owned-key envelope encryption for Kubernetes API data. | Customer-managed key controls and auditability are not configured. EKS 1.28+ encrypts by default; there is no additional charge for AWS-owned-key encryption. |

Reference: [AWS EKS default envelope encryption](https://docs.aws.amazon.com/eks/latest/userguide/envelope-encryption.html) and [Checkov per-resource suppression syntax](https://www.checkov.io/2.Basics/Suppressing%20and%20Skipping%20Policies.html).

## Cost and safety

- **No AWS infrastructure is modified by these comments.** No new KMS key, log group, NAT gateway, load balancer or VPC is created.
- You still pay for existing EKS control-plane, worker EC2, EBS and other existing AWS charges while they are running.
- **Do not use this cluster for sensitive data or public production workloads** with these exceptions in place.
- Keep AWS IAM permissions limited and monitor AWS billing even for the lab.
- When you have a known trusted public IP, set an approved CIDR allowlist in the EKS Terraform `vpc_config` only after reviewing that it won't lock out your access.
- Review these exceptions when the project moves out of a temporary sandbox. Remove them after the corresponding controls are implemented.

## Validation

After merging, manually run **EKS Lab - Terraform** with `action=plan`, `target_environment=dev`. The security stage should report the specific exceptions as skipped while enforcing all other checks. **Do not run Apply/Destroy merely to validate these comments.** Review the resulting plan for unexpected changes.
