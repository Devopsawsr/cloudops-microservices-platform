# Staging environment — configuration scaffold only

This Kustomize overlay is intentionally **not** registered with the Argo CD root application, and there is no Staging EKS cluster configured yet.

It currently reuses the shared `../../base` microservice definitions. The image references are placeholders (`REPLACE_ECR`) and **must not be deployed**.

Before activation:
1. Provision and verify the independent Staging AWS account/cluster and access controls.
2. Publish/promote the **same tested image digests** from QA; do not independently rebuild an image merely to change its environment tag.
3. Configure Staging Secrets, durable data services and dependencies.
4. Validate Kustomize rendering and run contract, smoke and release-candidate tests.
5. Register the Argo CD application only in the correct Staging cluster, then use an approval gate before promotion to Production.

The gateway Service is `ClusterIP`. An ALB Ingress, controller, cert and DNS must be configured separately before exposing HTTP externally.
