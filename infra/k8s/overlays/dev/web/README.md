# Dev: deploy Web only

This overlay includes **only** the shared ServiceAccount, Dev ConfigMap, Web Deployment and Web ClusterIP Service. It does not create the gateway, API services or an external LoadBalancer.

The Web image is built from `services/web/Dockerfile` (NGINX serving the real static application). The Kubernetes image must reference the image actually pushed to ECR. `REPLACE_ECR` intentionally blocks deployment until image publishing is complete.

## Local validation (no cluster mutation)

```bash
kubectl kustomize infra/k8s/overlays/dev/web
```

## First deployment after building and publishing the real Web image

1. Check EKS worker Pod slots/resources and correct cluster context.
2. Publish `cloudops-web` to ECR and replace its placeholder with the real registry path and immutable image digest.
3. Commit the manifest update through a PR, merge, and pull `main`.
4. Run `make deploy-web-dev CONFIRM_DEPLOY_WEB=YES` (includes a dry-run validation).
5. Confirm:
   ```bash
   kubectl rollout status deployment/web -n cloudops-dev
   kubectl get deployments,replicasets,pods,services -n cloudops-dev
   kubectl describe deployment web -n cloudops-dev
   kubectl port-forward -n cloudops-dev svc/web 8080:80
   # In a second terminal:
   curl -I http://localhost:8080/
   ```

Because the frontend references backend APIs, the UI may render while login/cart/order actions are unavailable until their APIs and the gateway are deployed. That is expected for this first exercise. The Web Service uses internal ClusterIP networking; `port-forward` is temporary access, not a production exposure model.

**Do not apply the full `infra/k8s/overlays/dev` overlay at this stage.**
