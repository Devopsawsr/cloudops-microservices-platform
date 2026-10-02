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
infra/k8s/overlays/        dev, QA and production Kustomize overlays
infra/argocd/              Argo CD project and applications
infra/terraform/           planned EKS/ECR/RDS infrastructure
scripts/                   image publishing and smoke tests
.github/workflows/         CI validation, builds and Trivy scans
docs/                      architecture and operating notes
```

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

## Deploy to kubeadm

```bash
kubectl get nodes
kubectl kustomize infra/k8s/overlays/dev >/tmp/cloudops-dev.yaml
kubectl apply --dry-run=server -f /tmp/cloudops-dev.yaml
kubectl apply -k infra/k8s/overlays/dev
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

## CI pipeline

The GitHub Actions workflow:

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
| Production | `cloudops-prod` | `0.1` | Manual approval |

## Current persistence scope

The kubeadm demonstration uses pod-local `emptyDir` storage for stateful APIs. This is acceptable only for temporary testing: data is lost when a pod is replaced and must not be used with horizontally scaled stateful services.

Before EKS production deployment, replace JSON-file storage with PostgreSQL/RDS, keep credentials in AWS Secrets Manager, and use IRSA workload identity.

## EKS production roadmap

- Terraform-managed VPC, EKS, ECR, IAM and RDS
- GitHub Actions OIDC authentication to AWS
- immutable image tags based on the Git commit SHA
- AWS Load Balancer Controller and ACM TLS certificate
- External Secrets with AWS Secrets Manager
- CloudWatch Container Insights and Prometheus/Grafana
- NetworkPolicy, Pod Security and least-privilege IRSA
- database backups, restore validation and disaster-recovery runbooks

## HTTP deployment

The lab endpoint uses HTTP because no domain or TLS certificate is configured. HTTPS will be introduced in EKS using Route 53, ACM and an Application Load Balancer.
