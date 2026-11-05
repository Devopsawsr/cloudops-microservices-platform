# CloudOps eBooks — Dev → QA → Staging → Production implementation plan

## Goal

Operate one application codebase containing the NGINX gateway, web frontend and nine API microservices. Build and test each changed service in CI, publish its immutable image to ECR, and promote the **same tested artifact** through Dev, QA, Staging and Production.

We start on the existing Terraform-managed `buddu-ebooks` EKS cluster as **Dev**. This is a learning cluster, **not a production-ready cluster**. No separate POC namespace or POC deployment stage is needed.

## Lab 1: declarative Dev namespace

```bash
# Run from the checked-out repository root after verifying the AWS account and cluster
kubectl config current-context
kubectl get nodes -o wide

# Validate the exact namespace declaration in Git
kubectl apply --dry-run=server -f infra/k8s/overlays/dev/namespace.yaml

# Bootstrap the Dev namespace only
kubectl apply -f infra/k8s/overlays/dev/namespace.yaml
kubectl get namespace cloudops-dev --show-labels
kubectl describe namespace cloudops-dev
```

The manifest under `infra/k8s/overlays/dev/namespace.yaml` is the **single source of truth for the Dev namespace**; do not create a second namespace definition for bootstrap.

**Do not apply `infra/k8s/overlays/dev/kustomization.yaml` yet.** It includes all 11 workload Deployments and ECR placeholder image references, and its gateway patch creates a LoadBalancer. The current t3.small worker had only 11 total Pod slots, with 4 occupied by system Pods. The application is not ready for deployment on that configuration.

## Implementation sequence

1. **Review infrastructure:** node readiness, CoreDNS, VPC CNI, events, allocatable memory, pod capacity, AWS EKS/IAM and the cost of a running cluster.
2. **Dev namespace:** apply the committed Namespace manifest; understand labels, Namespace scope, declarative apply and inspection.
3. **Kubernetes practice:** add a version-controlled NGINX training Deployment and ClusterIP Service scoped to Dev. Inspect Deployment → ReplicaSet → Pod, probes, DNS, events, self-healing and rollbacks. Keep training resources separate from the business microservices.
4. **Build and validate application:** review service Dockerfiles, API dependencies and config; run unit and integration checks, create/publish ECR images via GitHub Actions with AWS OIDC and security scanning.
5. **Capacity review:** size worker nodes and Pod slots for application, system add-ons, AWS Load Balancer Controller and observability; upgrade only after inspecting expected AWS cost and a Terraform plan.
6. **Dev rollout:** replace placeholder images with digest-pinned artifacts, update Kustomize overlays, use ConfigMaps and secure Secrets, and bring up microservices incrementally. Ensure readiness probes and internal smoke tests pass.
7. **Dev external access:** install AWS Load Balancer Controller using IRSA; expose an internal ClusterIP gateway through ALB Ingress, ACM and Route 53. Domain/DNS naming requires a separate decision; no public infrastructure is provisioned by this plan.
8. **Observability:** collect metrics and logs, set up practical dashboards and alarms, test failure signals and document recovery steps.
9. **GitOps:** onboard the validated Dev overlay to Argo CD; avoid simultaneously managing the same resources with manual apply and an automatic reconciler.
10. **Promotions:** configure QA, Staging and Production overlays and their target clusters/accounts; promote the same tested image digests with environment-specific configuration, tests and approvals. Independently deploy compatible microservices.
11. **Production hardening:** remove reliance on `emptyDir` for stateful data; use durable stores and tested backup/restore, identity and least privilege, security/network policies, scaling and reliable rollback.

## Repository boundaries

- **Application source:** one codebase under `services/`; microservices can be versioned and deployed independently.
- **Shared Kubernetes definitions:** `infra/k8s/base/`.
- **Environment configuration:** `infra/k8s/overlays/dev/`, `qa/`, `production/`; add `staging/` after Dev is validated. Current overlays are not automatically production-ready.
- **Infrastructure:** existing Terraform-managed Dev EKS; separate AWS account, access controls and state for later independently managed environments as appropriate.
- **Delivery:** CI builds immutable artifacts once, scans and tests them; CD/GitOps promotes approved image digests. Avoid hard-coded credentials and placeholder production settings.

## Verification criteria

- Committed Namespace manifest is the only source of truth for `cloudops-dev`.
- Developer can render/validate resources, verify API responses and troubleshoot Pods using `kubectl`.
- No public load balancer or unintended workload created during namespace bootstrap.
- ECR images, node capacity and Secrets are validated before Dev microservice rollout.
- QA, Staging and Production promotion uses the tested immutable artifact, not an unrelated rebuild.
