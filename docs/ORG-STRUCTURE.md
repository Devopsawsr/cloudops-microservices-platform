# Organization structure

This repository demonstrates **one product**, **three environments**, and controlled GitOps promotion.

```text
microservice/                          product + platform in one Git repo
  services/                            9 APIs + gateway + web (each has Dockerfile)
  packages/common/                     shared library
  .github/workflows/ci.yaml            CI builds every image
  infra/
    terraform/envs/{dev,qa,production} planned EKS, ECR and RDS infrastructure
    k8s/
      base/                            ServiceAccount, Deployments, ClusterIP
      overlays/dev                     ConfigMap debug, 1 replica, tag 0.1-dev, LB
      overlays/qa                      ConfigMap info, web x2, tag 0.1-qa, LB
      overlays/production              warn, HPA, PDB, 2 replicas, tag 0.1, LB
    argocd/
      project.yaml                     AppProject cloudops
      root-app.yaml                    app-of-apps
      apps/dev.yaml                    auto-sync
      apps/qa.yaml                     auto-sync
      apps/production.yaml             manual Sync (no auto)
```

**Promote like work:** build once → run in **dev** → same image retagged to **qa** → then **production**.

Start with `kubectl apply -k infra/k8s/overlays/dev`. After manual validation, Argo CD `cloudops-root` manages the three environment Applications.

Lab uses **three namespaces on one EKS**. Many companies later give production its own cluster. The **folder names stay the same**.
