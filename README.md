# CloudOps Microservices Platform

An end-to-end Kubernetes and DevOps demonstration project containing a web application, an NGINX API gateway, and nine independently deployable Python API services.

The project demonstrates containerization, service communication, Kubernetes operations, environment management, CI validation, security scanning, GitOps and an eventual migration from a kubeadm lab to Amazon EKS.

## Architecture

```text
Browser
   |
   v
Gateway (NGINX)
   |-- Web
   |-- Auth
   |-- Catalog
   |-- Cart
   |-- Orders
   |-- Learning ------> Certificates
   |-- Labs
   |-- Community
   `-- Leaderboard ---> Learning
```

## Repository layout

```text
services/                  web, gateway and API microservices
packages/common/           shared Python HTTP and storage helpers
infra/k8s/base/            reusable Kubernetes resources
infra/k8s/overlays/        Dev, QA, Staging and Production Kustomize overlays
infra/argocd/              Argo CD project and applications
infra/terraform/           existing Dev EKS lab; future environment infrastructure
scripts/                   image publishing and smoke tests
.github/workflows/         CI validation, builds and Trivy scans
docs/                      architecture and operating notes
```

## Dev first: declarative namespace bootstrap

We use a single application source codebase and promote immutable, tested microservice images through **Dev → QA → Staging → Production**. Our current EKS lab is the **Dev** environment, not a separate POC.

Start with the already-versioned namespace manifest. Do **not** apply the full Dev Kustomize overlay yet: it currently includes all 11 workloads, placeholder ECR images, and a LoadBalancer configuration.

```bash
# Check your active cluster before changing anything
kubectl config current-context
kubectl get nodes -o wide

# Inspect and validate the committed namespace manifest
kubectl apply --dry-run=server -f infra/k8s/overlays/dev/namespace.yaml

# Bootstrap only the namespace
kubectl apply -f infra/k8s/overlays/dev/namespace.yaml
kubectl get namespace cloudops-dev --show-labels
```

Read [Dev-first implementation plan](docs/DEV-TO-PRODUCTION-IMPLEMENTATION-PLAN.md) for the deployment sequence, resource capacity, CI/CD, ECR, ALB and observability stages. The full overlay remains in `infra/k8s/overlays/dev/` for later use after image and capacity readiness.

## Local validation

Requirements: Docker with Compose v2, Python 3, kubectl and access to a Kubernetes cluster.

```bash
make validate
make compose-up
curl http://localhost/api/health
BASE_URL=http://localhost ./scripts/smoke-test.sh
make compose-down
```

Open `http://localhost` to use the website.

## Publish the kubeadm images

Use Docker Hub or another registry accessible from every kubeadm node.

```bash
docker login
export REGISTRY=docker.io/REPLACE_WITH_YOUR_USER
export IMAGE_TAG=0.1-dev
./scripts/build-and-push.sh
```

Replace `REPLACE_ECR` in `infra/k8s/overlays/dev/kustomization.yaml` with the same registry namespace. For Docker Hub, the result should resemble:

```yaml
newName: docker.io/your-user/cloudops-gateway
newTag: 0.1-dev
```

## Deploy to Kubernetes

The full Dev deployment below is **not ready** until images and node capacity are reviewed. Start with `make bootstrap-dev` instead.

```bash
kubectl get nodes
kubectl kustomize infra/k8s/overlays/dev >/tmp/cloudops-dev.yaml
kubectl apply --dry-run=server -f /tmp/cloudops-dev.yaml
make deploy-dev CONFIRM_DEPLOY_DEV=YES
kubectl rollout status deployment/gateway -n cloudops-dev
kubectl get all -n cloudops-dev
```

For a kubeadm cluster without MetalLB, use port forwarding:

```bash
kubectl port-forward -n cloudops-dev service/gateway 8080:80
```

In another terminal:

```bash
BASE_URL=http://localhost:8080 ./scripts/smoke-test.sh
```

## Kubernetes operations to demonstrate

```bash
# Self-healing
kubectl delete pod -n cloudops-dev -l app=gateway
kubectl get pods -n cloudops-dev -w

# Scaling
kubectl scale deployment/web -n cloudops-dev --replicas=2
kubectl get pods -n cloudops-dev -l app=web

# Rollout and rollback
kubectl set image deployment/web web=nginx:invalid-tag -n cloudops-dev
kubectl rollout status deployment/web -n cloudops-dev
kubectl rollout undo deployment/web -n cloudops-dev

# Troubleshooting
kubectl get events -n cloudops-dev --sort-by=.metadata.creationTimestamp
kubectl logs -n cloudops-dev deployment/gateway
kubectl describe deployment gateway -n cloudops-dev
```

## CI and release status

The repository currently has **two** separate workflows: `.github/workflows/eks-lab-terraform.yml` for the Terraform-managed Dev EKS cluster, and `.github/workflows/validate-application.yml` for pull-request validation of Python, Compose, and Kustomize overlays.

**Publishing and promotion are not yet implemented.** The existing overlays still contain `REPLACE_ECR` and must not be applied to EKS until real images, credentials, resource capacity and Secrets have been prepared. A successful YAML render does not mean the application is release-ready.

The intended production-style build pipeline will:

1. Compiles all Python services.
2. Validates Docker Compose.
3. Renders all Kustomize overlays.
4. Builds all 11 images independently.
5. Scans every image for high and critical vulnerabilities using Trivy.

Publishing to ECR is separated from pull-request validation and will be enabled after the AWS account, ECR registry and GitHub OIDC role are configured.

## Argo CD

The Argo CD manifests use `https://github.com/Devopsawsr/cloudops-microservices-platform.git`. Change this URL if you select a different repository name, then apply:

```bash
kubectl apply -f infra/argocd/project.yaml
kubectl apply -f infra/argocd/root-app.yaml
```

Development and QA use automated synchronization. Production requires a manual Argo CD sync.

## Environment strategy

| Environment | Namespace | Image tag | Delivery |
|---|---|---|---|
| Development | `cloudops-dev` | `0.1-dev` | Automated |
| QA | `cloudops-qa` | `0.1-qa` | Automated |
| Staging (config scaffold only) | `cloudops-staging` | Placeholder pending digest promotion | Approval gate |
| Production | `cloudops-prod` | `0.1` | Manual approval |

## Current persistence scope

The kubeadm demonstration uses pod-local `emptyDir` storage for stateful APIs. This is acceptable only for temporary testing: data is lost when a pod is replaced and must not be used with horizontally scaled stateful services.

Before EKS production deployment, replace JSON-file storage with a durable data store (for example RDS), keep credentials in AWS Secrets Manager, and use EKS Pod Identity or IRSA as appropriate.

## EKS production roadmap

- Terraform-managed VPC, EKS, ECR, IAM and RDS
- GitHub Actions OIDC authentication to AWS
- immutable image tags based on the Git commit SHA
- AWS Load Balancer Controller and ACM TLS certificate
- External Secrets with AWS Secrets Manager
- CloudWatch Container Insights and Prometheus/Grafana
- NetworkPolicy, Pod Security and least-privilege IRSA
- database backups, restore validation and disaster-recovery runbooks

## Release promotion and HTTPS

See [Environment and release workflow](docs/ENVIRONMENT-RELEASE-STRATEGY.md). Dev runs in the existing EKS learning cluster. QA, Staging and Production configuration files are **not proof of deployed infrastructure**. Images should be built and scanned once, then promoted by digest under review and environment-specific controls.

HTTPS requires ALB Ingress, an ACM certificate and Route 53. Existing LoadBalancer Service patches should be replaced with the planned Ingress approach before deploying the full application.
