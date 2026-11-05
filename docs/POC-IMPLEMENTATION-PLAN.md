# CloudOps eBooks — hands-on POC implementation plan

## Goal

Deploy the app from this repository to the existing Terraform-managed `buddu-ebooks` Amazon EKS lab, make it available at `https://poc-ebooks.buddu.online`, and implement monitoring and alerting. Current code changes bootstrap **only the namespace**, not the application.

## Engineering approach

1. **Cluster baseline:** capture node readiness, capacity, Pod slots, CNI/CoreDNS, resource requests and events.
2. **Declarative Kubernetes lab:** deploy `infra/k8s/overlays/poc` namespace, validate and describe it; then a small NGINX Deployment/ClusterIP example as committed manifests in a separate lab overlay.
3. **Application readiness:** validate 11 source/Docker images and API routes locally; build and scan images using CI; publish to ECR with immutable SHA/digest references.
4. **Capacity:** resize the single managed node if necessary, based on summed resource requests, DaemonSets, DNS, ALB controller and monitoring requirements. An initial t3.small has only 11 total Pod slots; adding a second namespace does not create capacity.
5. **POC rollout:** add the shared `infra/k8s/base` to the POC overlay, with ConfigMap/Secrets integration, appropriate replicas and probes. Apply and inspect; run `scripts/smoke-test.sh`.
6. **External access:** install AWS Load Balancer Controller using its dedicated IAM role; apply ALB Ingress to the *ClusterIP* gateway; validate ACM HTTPS and Route 53 `poc-ebooks.buddu.online`.
7. **Observability:** set up lightweight cluster and application metrics/logs, dashboards, HTTP uptime checks and alerts; verify alerts with a controlled failure drill.
8. **GitOps/CD:** add Argo CD POC application after image and health readiness; configure GitHub Actions OIDC to build/scan/publish and promote the same image digest, with reviewed manifest changes.
9. **Reliability and handover:** address `emptyDir` data loss, Secrets and backup strategy; document rollback, recovery, security, costs and acceptance tests.

## Environment model

- **Source:** one application codebase (`services/`), one common Kubernetes base (`infra/k8s/base/`).
- **Configuration:** overlays for POC, Dev, QA, Staging (to be added when required), and Production.
- **Release:** Dev → QA → Staging → Production is a *chosen process*, not a Kubernetes requirement. POC is a demonstration gate that can precede that lifecycle.
- **Infrastructure:** separate state and credentials for independently managed environments; separate production AWS account/cluster when implemented.
- **Application artifacts:** independently deploy affected microservices, while preserving compatibility; promote tested immutable image digests across accounts/registries.
- **Operations:** Git-managed desired state; `kubectl` remains the diagnostic tool. Argo CD owns reconciled manifests after onboarding, not concurrent manual deploy controllers.

## Acceptance criteria

- One healthy EKS worker, adequate Pod slots and requests for chosen services.
- Git version controls the POC namespace and all application configuration.
- All deployed Pods Ready and internal API tests pass.
- HTTPS site reachable with valid certificate; ALB healthy targets; DNS correct.
- Metrics, logs, dashboard and test alert available.
- Pipeline can deploy and roll back a specific image digest.
- No unreviewed long-lived credentials in Git; no false claims of durable state while using `emptyDir`.
