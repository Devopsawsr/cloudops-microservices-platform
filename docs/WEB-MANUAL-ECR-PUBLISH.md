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

The job does the following:

1. Checks out the source commit.
2. Builds the real Web image using `services/web/Dockerfile` and repository-root build context.
3. Starts the image locally and verifies that HTTP `/` responds and contains expected website text.
4. Scans HIGH/CRITICAL fixed vulnerabilities with Trivy and blocks publishing on findings.
5. Assumes the dedicated OIDC publishing role, verifies AWS account and repository, logs into ECR.
6. Publishes a uniquely tagged Web image and verifies the digest in ECR.
7. Writes the tag and immutable `repository@sha256:...` image reference to the workflow summary.

## Next step

After the image has been published, update **only** the Web-only Dev Kustomize overlay (`infra/k8s/overlays/dev/web/kustomization.yaml`) to use the verified repository/digest. Review through a PR before running `make deploy-web-dev CONFIRM_DEPLOY_WEB=YES`. Do not apply the full Dev overlay yet.

This pipeline does not create Kubernetes Pods, Deployments, or LoadBalancers, and does not build the other ten services.
