# kubeadm Deployment and Validation Runbook

This runbook provides the evidence required to demonstrate an end-to-end Kubernetes deployment.

## 1. Cluster readiness

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

All nodes and CNI pods must be ready before application deployment.

## 2. Publish images

```bash
export REGISTRY=docker.io/your-user
export IMAGE_TAG=0.1-dev
docker login
./scripts/build-and-push.sh
```

Replace `REPLACE_ECR` in the development overlay with the value of `REGISTRY`.

## 3. Pre-deployment validation

```bash
python3 -m compileall -q packages services
docker compose config --quiet
kubectl kustomize infra/k8s/overlays/dev >/tmp/cloudops-dev.yaml
kubectl apply --dry-run=server -f /tmp/cloudops-dev.yaml
```

## 4. Deployment

```bash
kubectl apply -k infra/k8s/overlays/dev
kubectl wait --for=condition=Available deployment --all -n cloudops-dev --timeout=300s
kubectl get all -n cloudops-dev -o wide
```

## 5. Functional validation

```bash
kubectl port-forward -n cloudops-dev service/gateway 8080:80
```

In another terminal:

```bash
BASE_URL=http://localhost:8080 ./scripts/smoke-test.sh
```

## 6. Service discovery

```bash
kubectl run network-test --rm -it --restart=Never \
  --image=curlimages/curl -n cloudops-dev -- \
  curl -fsS http://catalog:8080/api/books
```

## 7. Self-healing

```bash
kubectl get pods -n cloudops-dev -l app=gateway
kubectl delete pod -n cloudops-dev -l app=gateway
kubectl get pods -n cloudops-dev -l app=gateway -w
```

Record that the Deployment creates a replacement pod.

## 8. Scaling

```bash
kubectl scale deployment/web -n cloudops-dev --replicas=3
kubectl rollout status deployment/web -n cloudops-dev
kubectl get pods -n cloudops-dev -l app=web -o wide
```

## 9. Rollout and rollback

```bash
kubectl set image deployment/web web=nginx:invalid-tag -n cloudops-dev
kubectl rollout status deployment/web -n cloudops-dev --timeout=60s || true
kubectl get pods -n cloudops-dev -l app=web
kubectl rollout undo deployment/web -n cloudops-dev
kubectl rollout status deployment/web -n cloudops-dev
```

## 10. Troubleshooting commands

```bash
kubectl get events -n cloudops-dev --sort-by=.metadata.creationTimestamp
kubectl describe pod -n cloudops-dev POD_NAME
kubectl logs -n cloudops-dev POD_NAME
kubectl logs -n cloudops-dev POD_NAME --previous
kubectl get endpoints -n cloudops-dev
kubectl top nodes
kubectl top pods -n cloudops-dev
```

## 11. Cleanup

```bash
kubectl delete -k infra/k8s/overlays/dev
```

Run cleanup only when the test environment is no longer required.
