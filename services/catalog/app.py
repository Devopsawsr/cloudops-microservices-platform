#!/usr/bin/env python3
from common.books import BOOKS
from common.server import App

app = App("catalog")


def books(_query):
    return 200, BOOKS


app.get("/api/books", books)

if __name__ == "__main__":
    app.serve()
