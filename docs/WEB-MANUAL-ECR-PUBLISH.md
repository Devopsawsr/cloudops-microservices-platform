# Manual Web image build and publish to ECR

Workflow: `.github/workflows/manual-web-ecr.yml`

This is the **first service-specific image publishing workflow**. It runs only when manually started from the GitHub Actions tab on `main` and **does not deploy to EKS**.

## Target image

- AWS account: `981625497990`
- Region: `us-east-1`
- **Dedicated Web ECR repository:** `reddy/buddu-ebooks-web`
- Full repository URI: `981625497990.dkr.ecr.us-east-1.amazonaws.com/reddy/buddu-ebooks-web`
- Image tag: `web-<12-char-commit>-<run-id>-<attempt>`

**Important:** This Web-specific ECR repository is distinct from the original shared `reddy/buddu-ebooks` repository. The workflow checks that it exists and fails if missing; it does **not** create the repository. Use Terraform to manage ECR repositories in the future and review any AWS costs before provisioning.

## Prerequisites (one-time)

1. Create or verify ECR repository `reddy/buddu-ebooks-web` in `us-east-1`. Prefer Terraform rather than a manual click for long-lived infrastructure.
2. Create a least-privilege IAM role trusted by GitHub's OIDC provider scoped to this GitHub repository, the `main` ref and the `aws-dev` GitHub environment. Review actual OIDC subject constraints when configuring the trust policy (environment-based subjects use `environment:aws-dev` rather than `ref:refs/heads/main`).
3. Grant this role `ecr:GetAuthorizationToken` on `*`, and repository-scoped actions `ecr:BatchCheckLayerAvailability`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`, `ecr:PutImage`, and `ecr:DescribeImages` only on `arn:aws:ecr:us-east-1:981625497990:repository/reddy/buddu-ebooks-web`.
4. Set GitHub **Environment** `aws-dev` secret `AWS_ECR_PUBLISH_ROLE_ARN` to this role ARN. This is intentionally separate from the privileged Terraform role.
5. Ensure any environment protection rules allow the intended manual workflow to run.

## Manually trigger

In GitHub: **Actions → Build and publish Web image to ECR → Run workflow → Branch: main → Run workflow**.

## Visible GitHub Actions job graph

GitHub Actions renders **five separate dependent jobs**, so each appears as its own stage in the workflow visualization:

```text
01 | Validate source and Dockerfile
               |
02 | Build and smoke-test Web image
               |
03 | Security scan (Trivy)
               |
04 | Publish approved image to ECR
               |
05 | Verify published ECR digest
```

Jobs use `needs:` dependencies. If a stage fails, downstream stages do not run.

Each GitHub-hosted job starts with a fresh runner. The build stage therefore saves its **tested Docker image** as a one-day GitHub Actions artifact; the scan and publish stages download and load that *same image*, rather than rebuilding it. Publishing is gated on the Trivy result. Only the publishing and verification jobs request AWS OIDC access using the `aws-dev` environment.

Open **Actions → Build and publish Web image to ECR → the selected run → Summary** to view the separate job graph. Click an individual job to inspect its step-level logs.

Changes to a workflow file apply to **new workflow runs**; already-started runs retain their original job graph.

## Next step

After the image has been published, update **only** the Web-only Dev Kustomize overlay (`infra/k8s/overlays/dev/web/kustomization.yaml`) to use the verified repository/digest. Review through a PR before running `make deploy-web-dev CONFIRM_DEPLOY_WEB=YES`. Do not apply the full Dev overlay yet.

This pipeline does not create Kubernetes Pods, Deployments, or LoadBalancers, and does not build the other ten services.
