# Environment and release architecture

## Current state versus target architecture

| Area | Present in Git | Running in AWS | Next step |
|---|---|---|---|
| Dev EKS infrastructure | Terraform under `infra/terraform/envs/dev` | Existing `buddu-ebooks` Dev cluster | Continue verifying health and capacity |
| Microservice source | 11 service directories | Not yet deployed to EKS | Test, build, scan and publish images |
| Dev Kubernetes overlay | `infra/k8s/overlays/dev` | Namespace bootstrap only after manual apply | Replace registry placeholders; remove gateway LoadBalancer patch in favor of reviewed Ingress |
| QA overlay | `infra/k8s/overlays/qa` | Not deployed | Configure own cluster, secrets, promotion gate |
| Staging overlay | `infra/k8s/overlays/staging` | Not deployed | Promote same tested images and configure staging infrastructure |
| Production overlay | `infra/k8s/overlays/production` | Not deployed | Dedicated infrastructure, approvals, hardened access and durable data |
| Argo CD declarations | `infra/argocd` | Not validated as installed | Review target clusters and image readiness before enabling sync |
| Application release CI/CD | Validation only | No ECR promotion established | Implement build, security scan, digest-pinned image publishing |

**Do not apply the Argo CD root Application in the Dev learning cluster.** The existing root includes Dev/QA/Production application definitions and Dev/QA auto-sync. Its destination points at the in-cluster Kubernetes API and could deploy workloads into the wrong account/cluster. Multi-account Argo CD destinations and authorization need to be designed first.

## Single application codebase and environment separation

The 11 microservice sources live under `services/`, each with its own Dockerfile. Kubernetes common Deployment/Service definitions live under `infra/k8s/base/`. Differences between environments are expressed under `infra/k8s/overlays/{dev,qa,staging,production}/`.

A separate environment overlay is **configuration**, not a separate copy of the application source code. Use the same commit-tested image digest as it passes Dev, QA, Staging and Production. Deploy compatible services independently when needed. Feature branches and pull requests validate before merge; a merge is not an automatic production release.

### Intended promotion gates

1. **PR/CI:** Python checks, unit tests, application builds, Kubernetes rendering, vulnerability and image checks.
2. **Build:** publish the changed image to ECR using GitHub Actions OIDC. Record SHA and image digest.
3. **Dev:** deploy digest to the Dev cluster; smoke tests and integration tests.
4. **QA:** promote the **same digest** to QA; regression and contract tests.
5. **Staging:** promote that digest into the Staging account/registry; production-like acceptance tests.
6. **Production:** approval, canary/rolling rollout, monitoring, rollback to the previously known-good digest.

If images are copied between accounts, validate the destination image digest and signing/provenance; treat registry differences explicitly rather than assuming tags prove identity.

### Deployment ownership

- **Terraform:** provisions cloud resources and keeps a separate state for independently managed environments.
- **Kubernetes manifests/Kustomize:** defines and overlays app desired state.
- **Helm:** installs and versions complex cluster add-ons where appropriate.
- **GitHub Actions:** runs validations and image supply-chain steps.
- **Argo CD:** reconciles approved manifests into their authorized cluster destinations once installed. Avoid overlapping controllers and direct manual release changes.
- **kubectl:** debugging, controlled experiments, emergency operations and inspection.

## Security and operations expectations

- AWS account boundaries: Dev/QA may share a nonproduction account, Staging its own account, Production isolated. All account choices need independent OIDC/roles and review.
- Keep secrets outside Git; use AWS Secrets Manager and an appropriate Kubernetes integration, plus least-privilege service identities.
- Use resource requests/limits, probe checks and Pod-capacity analysis; the existing t3.small worker cannot host all eleven workload Pods with system components.
- The current `emptyDir` volumes are ephemeral and must be replaced with durable state before meaningful load and production operation.
- Choose `ClusterIP` for the gateway when using ALB Ingress; review health checks, HTTPS, DNS, network policy and costs.
- Each promotion should record environment, image digest, source commit, approvals, release result, monitoring evidence and rollback instructions.

## Commands for engineering workflow

```bash
# CI-style local validation. Does not contact AWS.
make validate-k8s

# Safe namespace-only Dev bootstrap. Requires the correct kubeconfig context.
kubectl config current-context
make bootstrap-dev

# Do not run full Dev deploy until images, secrets and capacity are ready.
make deploy-dev CONFIRM_DEPLOY_DEV=YES
```

A successful Kustomize render proves only that Kustomize can assemble configuration; it does not validate readiness, registry access, runtime behavior or infrastructure provisioning.

## Interview summary (only after completed hands-on work)

"We keep a common microservices source tree and reusable Kubernetes base with environment-specific Kustomize overlays. Pull requests run automated validation. The release target is to build and scan a changed microservice image once, promote its immutable digest through Dev, QA, Staging and Production with approvals, and use Argo CD for Git-based reconciliation. Infrastructure and credentials are isolated by environment and AWS account."

**Do not claim CI/CD publishing, multi-account rollout, observability, or production disaster recovery have been implemented until they are actually built and tested.**
