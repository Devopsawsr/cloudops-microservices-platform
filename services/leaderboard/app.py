#!/usr/bin/env python3
import os

from common.http import get_json
from common.server import App
from common.store import load

app = App("leaderboard")
LEARNING_URL = os.environ.get("LEARNING_URL", "http://learning:8080")


def board(_query):
    exams = get_json(f"{LEARNING_URL}/api/exams") or load("exams.json")
    ranked = sorted(exams, key=lambda x: (-int(x.get("score") or 0), x.get("when") or ""))
    return 200, ranked[:20]


app.get("/api/leaderboard", board)

if __name__ == "__main__":
    app.serve()
