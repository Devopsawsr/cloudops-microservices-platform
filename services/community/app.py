#!/usr/bin/env python3
from datetime import datetime, timezone

from common.server import App
from common.store import load, save

app = App("community")


def list_threads(_query):
    return 200, load("threads.json")


def post_thread(payload):
    thread = {
        "name": payload.get("name") or "Learner",
        "title": (payload.get("title") or "").strip(),
        "body": (payload.get("body") or "").strip(),
        "when": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    }
    if not thread["title"] or not thread["body"]:
        return 400, {"message": "Title and question are required."}
    rows = load("threads.json")
    rows.insert(0, thread)
    save("threads.json", rows)
    return 201, thread


app.get("/api/community", list_threads)
app.post("/api/community", post_thread)

if __name__ == "__main__":
    app.serve()
