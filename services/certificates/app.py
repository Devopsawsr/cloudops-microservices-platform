#!/usr/bin/env python3
from common.server import App
from common.store import load, save

app = App("certificates")


def list_certs(_query):
    return 200, load("certificates.json")


def issue(payload):
    certs = load("certificates.json")
    cert = dict(payload)
    cert["id"] = payload.get("id") or f"CERT-{len(certs) + 1:04d}"
    certs.append(cert)
    save("certificates.json", certs)
    return 201, cert


app.get("/api/certificates", list_certs)
app.post("/api/certificates", issue)

if __name__ == "__main__":
    app.serve()
