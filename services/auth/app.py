#!/usr/bin/env python3
from common.server import App
from common.store import digest, load, save

app = App("auth")


def signup(payload):
    name = (payload.get("name") or "").strip()
    email = (payload.get("email") or "").strip().lower()
    password = payload.get("password") or ""
    if not name or not email or len(password) < 6:
        return 400, {"message": "Name, email, and a 6+ character password are required."}
    rows = load("users.json")
    if any(u.get("email") == email for u in rows):
        return 409, {"message": "That email already has an account. Login instead."}
    row = {"name": name, "email": email, "password": digest(password)}
    rows.append(row)
    save("users.json", rows)
    return 201, {"name": row["name"], "email": row["email"]}


def login(payload):
    email = (payload.get("email") or "").strip().lower()
    password = payload.get("password") or ""
    rows = load("users.json")
    hit = next((u for u in rows if u.get("email") == email and u.get("password") == digest(password)), None)
    if not hit:
        return 401, {"message": "Email or password is wrong."}
    return 200, {"name": hit["name"], "email": hit["email"]}


app.post("/api/signup", signup)
app.post("/api/login", login)

if __name__ == "__main__":
    app.serve()
