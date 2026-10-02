#!/usr/bin/env python3
from datetime import datetime, timezone

from common.books import NAMES
from common.server import App
from common.store import load, save

app = App("orders")


def list_orders(_query):
    return 200, load("orders.json")


def buy(payload):
    items = payload.get("items") or []
    books = ", ".join(NAMES.get(i.get("id"), i.get("id")) for i in items)
    row = {
        "name": payload.get("name") or "Learner",
        "email": (payload.get("email") or "").lower(),
        "books": books,
        "when": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    }
    rows = load("orders.json")
    rows.append(row)
    save("orders.json", rows)
    return 201, {"message": f"Purchased: {books}", "order": row}


app.get("/api/orders", list_orders)
app.post("/api/buy", buy)

if __name__ == "__main__":
    app.serve()
