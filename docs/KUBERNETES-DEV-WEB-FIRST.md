# Kubernetes Dev: first Web deployment (Kustomize)

This phase deploys **only the Web microservice** to an existing EKS cluster. AWS infrastructure remains owned by Terraform; application resources are managed by Kubernetes/Kustomize. **No Kubernetes changes are made by merging this PR.** No LoadBalancer, Ingress, ALB, NAT gateway, KMS key, or new AWS resource is added.

## What is deployed

`infra/k8s/overlays/dev/kustomization.yaml` composes these existing files:

| Source | Kubernetes resource |
| --- | --- |
| `overlays/dev/namespace.yaml` | Namespace `cloudops-dev` |
| `overlays/dev/common/configmap.yaml` | ConfigMap `cloudops-config` |
| `base/common/serviceaccount.yaml` | ServiceAccount `cloudops` |
| `base/web/deployment.yaml` | Web Deployment (one replica) with readiness and liveness probes |
| `base/web/service.yaml` | Web Service (ClusterIP, port 80) |

A previously successful GitHub Actions ECR build [#42081295085](https://github.com/Devopsawsr/cloudops-microservices-platform/actions/runs/42081295085) published the immutable image tag:

```text
981625497990.dkr.ecr.us-east-1.amazonaws.com/reddy/buddu-ebooks-web:web-eff6d8b0d5b7-42081295085-1
```

This tag is pinned in the Dev overlay. Confirm it still exists before deploying because ECR lifecycle rules can remove old images. When using a newer image, update only the Dev overlay tag with the image verified by the publishing workflow.

## One-time local prerequisites

You need the AWS CLI, kubectl, credentials for the EKS cluster and access to ECR. Our Terraform lab uses `us-east-1`, cluster `reddy-ebooks`, and local AWS profile `eks-lab`.

```bash
export AWS_PROFILE=eks-lab
export AWS_DEFAULT_REGION=us-east-1
aws eks update-kubeconfig --region us-east-1 --name reddy-ebooks --profile eks-lab
kubectl config current-context
kubectl get nodes
```

Review the ECR image tag without making changes:

```bash
aws ecr describe-images \
  --repository-name reddy/buddu-ebooks-web \
  --image-ids imageTag=web-eff6d8b0d5b7-42081295085-1 \
  --region us-east-1 \
  --profile eks-lab
```

## Render and review before deploying

From the repository root:

```bash
kubectl kustomize infra/k8s/overlays/dev
kubectl diff -k infra/k8s/overlays/dev
```

`kubectl diff` may return exit code `1` when differences are found. Confirm the only desired resources are one namespace, one ConfigMap, one ServiceAccount, one Deployment, and one ClusterIP Service. If the namespace does not exist yet, a local dry-run can be used to inspect rendering first.

## Apply Dev Web only

```bash
kubectl apply -k infra/k8s/overlays/dev
kubectl -n cloudops-dev rollout status deployment/web --timeout=180s
kubectl -n cloudops-dev get deployment,replicaset,pods,service
kubectl -n cloudops-dev describe deployment web
```

If Pods report `ImagePullBackOff`, inspect `kubectl -n cloudops-dev describe pod <pod-name>` and confirm node-role permissions, image tag and ECR connectivity. The Web container listens on port 80.

## Test without a paid load balancer

```bash
kubectl -n cloudops-dev port-forward service/web 8080:80
```

In another terminal:

```bash
curl --fail http://localhost:8080/
```

Open http://localhost:8080 in your browser. Port-forwarding is local and temporary; stop it with Ctrl+C.

## Clean up only the Web application

```bash
kubectl delete -k infra/k8s/overlays/dev
```

This deletes the listed resources including the Dev namespace. Do not do this if other Dev workloads have been added to that namespace; namespace deletion would delete those too. Terraform is **not** run by these commands.

## Multi-environment policy

- **Base** contains reusable per-service manifests (Web now, additional services later).
- **Overlays** contain namespace, image identity, replica count and environment settings.
- Dev is **Web only** at this stage, and QA/Staging/Production overlays are **not yet ready for deployment**: they contain placeholders and reference additional services.
- Do not use the existing `infra/k8s/base` aggregate or apply QA/Staging/Production overlays until each is intentionally configured and validated.
- For more secure production isolation, prefer separate AWS accounts and/or clusters; namespaces alone are not a strict security boundary.
- Future GitHub Actions CD stages can validate → render → deploy → rollout-check → smoke-test. This PR only prepares the manifests and validates them in CI.
