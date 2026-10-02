import json
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def get_json(url, timeout=4):
    req = Request(url, headers={"Accept": "application/json"})
    try:
        with urlopen(req, timeout=timeout) as res:
            return json.loads(res.read().decode() or "[]")
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError):
        return []


def post_json(url, payload, timeout=4):
    body = json.dumps(payload).encode()
    req = Request(url, data=body, method="POST", headers={"Content-Type": "application/json"})
    try:
        with urlopen(req, timeout=timeout) as res:
            return json.loads(res.read().decode() or "{}")
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError):
        return {}
