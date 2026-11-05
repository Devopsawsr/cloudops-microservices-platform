# CloudOps POC — Git-managed bootstrap

This overlay **only creates the `cloudops-poc` namespace** on the existing EKS lab. It intentionally does not deploy any application workloads, ingress, or load balancers.

## First lab: namespace managed as code

From the repository root, with the correct EKS context:

```bash
aws sts get-caller-identity --profile eks-lab
aws eks update-kubeconfig --name buddu-ebooks --region us-east-1 --profile eks-lab
kubectl config current-context
kubectl get nodes -o wide

# Render and inspect the exact objects before changing the cluster
kubectl kustomize infra/k8s/overlays/poc
kubectl apply --dry-run=server -k infra/k8s/overlays/poc

# Bootstrap once. Later, GitOps will manage the same overlay.
kubectl apply -k infra/k8s/overlays/poc
kubectl get namespace cloudops-poc --show-labels
kubectl describe namespace cloudops-poc
```

Do **not** use `kubectl apply -k infra/k8s/overlays/dev` on this small POC node. The dev overlay presently references `REPLACE_ECR` and includes 11 application Deployments.

## Why we separate POC and application rollout

- The first lab verifies Namespace objects, labels, declarative apply, Kustomize rendering and repeatability.
- The initial t3.small worker has an EKS Pod limit of 11, with system Pods consuming several slots; it cannot host all 11 application Deployments simultaneously.
- Later tasks: provision ECR repositories, build/publish pinned images, review capacity and stateful data, then add `../../base` and targeted POC patches.
- Keep the gateway internal (`ClusterIP`) when adding AWS ALB Ingress; don't copy the dev `gateway-lb.yaml` patch.
- Configure ACM, Route 53 and the AWS Load Balancer Controller only after internal application smoke tests pass.
- Don't expose real user data in the POC while APIs still rely on `emptyDir` for persistence.

## Target release flow

One application source codebase and shared Kubernetes base; environment overlays for POC, Dev, QA, Staging and Production. CI builds immutable images once and promotes the same tested digests through gated environments. Accounts, cluster access, Secrets and Terraform states remain environment-specific.

This overlay is purposefully **not** added to the Argo CD root application yet. We will introduce a reviewed POC Argo CD Application after images and cluster capacity are ready, to avoid automatic deployment of incomplete workloads.
