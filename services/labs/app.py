#!/usr/bin/env python3
from common.server import App

app = App("labs")

LABS = [
    {"id": "terraform", "name": "Terraform apply", "note": "Plan a node group change, then apply."},
    {"id": "eks", "name": "EKS rollout", "note": "kubectl get, then rollout status."},
    {"id": "mlops", "name": "MLOps loop", "note": "Train, register, deploy, watch."},
]


def list_labs(_query):
    return 200, LABS


app.get("/api/labs", list_labs)

if __name__ == "__main__":
    app.serve()
