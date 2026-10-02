#!/usr/bin/env python3
import os
from datetime import datetime, timedelta, timezone

from common.books import NAMES
from common.http import post_json
from common.server import App
from common.store import load, save

app = App("learning")
CERTIFICATES_URL = os.environ.get("CERTIFICATES_URL", "http://certificates:8080")


def list_exams(_query):
    return 200, load("exams.json")


def sit_exam(payload):
    score = int(payload.get("score") or 0)
    book_id = payload.get("book_id") or ""
    passed = score >= 70
    email = (payload.get("email") or "").lower()
    name = (payload.get("name") or "").strip()
    if not name:
        hit = next((u for u in load("users.json") if u.get("email") == email), None)
        name = (hit or {}).get("name") or (email.split("@")[0] if email else "Learner")
    row = {
        "name": name,
        "email": email,
        "book": NAMES.get(book_id, book_id),
        "score": score,
        "passed": passed,
        "when": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    }
    rows = load("exams.json")
    rows.append(row)
    save("exams.json", rows)
    if passed:
        issued = datetime.now(timezone.utc)
        until = issued + timedelta(days=365)
        cert = {
            "name": name,
            "email": row["email"],
            "book": row["book"],
            "score": score,
            "when": issued.strftime("%Y-%m-%d"),
            "valid_until": until.strftime("%Y-%m-%d"),
            "valid_for": "1 year",
            "wish": "All the best for the year ahead.",
        }
        issued_cert = post_json(f"{CERTIFICATES_URL}/api/certificates", cert)
        if issued_cert:
            row["certificate"] = issued_cert
    return 200, row


app.get("/api/exams", list_exams)
app.post("/api/exam", sit_exam)

if __name__ == "__main__":
    app.serve()
