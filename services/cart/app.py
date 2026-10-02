#!/usr/bin/env python3
from common.server import App
from common.store import load, save

app = App("cart")


def get_cart(query):
    email = (query.get("email") or "").strip().lower()
    rows = load("carts.json")
    hit = next((c for c in rows if c.get("email") == email), {"email": email, "items": []})
    return 200, hit


def save_cart(payload):
    email = (payload.get("email") or "").strip().lower()
    items = payload.get("items") or []
    if not email:
        return 400, {"message": "Email is required."}
    rows = load("carts.json")
    found = False
    for row in rows:
        if row.get("email") == email:
            row["items"] = items
            found = True
            break
    if not found:
        rows.append({"email": email, "items": items})
    save("carts.json", rows)
    return 200, {"email": email, "items": items}


app.get("/api/cart", get_cart)
app.post("/api/cart", save_cart)

if __name__ == "__main__":
    app.serve()
