import hashlib
import json
import os
from pathlib import Path

DATA = Path(os.environ.get("DATA_DIR", "/data"))
DATA.mkdir(parents=True, exist_ok=True)
PASS_SALT = os.environ.get("PASS_SALT", "cloudops-academy-demo")


def load(name):
    path = DATA / name
    if not path.exists():
        return []
    return json.loads(path.read_text())


def save(name, rows):
    path = DATA / name
    path.write_text(json.dumps(rows, indent=2))


def digest(password):
    return hashlib.sha256(f"{PASS_SALT}:{password}".encode()).hexdigest()
