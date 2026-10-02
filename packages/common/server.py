import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


class App:
    def __init__(self, name):
        self.name = name
        self.gets = {}
        self.posts = {}

    def get(self, path, fn):
        self.gets[path] = fn

    def post(self, path, fn):
        self.posts[path] = fn

    def serve(self, host="0.0.0.0", port=8080):
        app = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, fmt, *args):
                return

            def _json(self, code, payload):
                body = json.dumps(payload).encode()
                self.send_response(code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_OPTIONS(self):
                self.send_response(204)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
                self.send_header("Access-Control-Allow-Headers", "content-type")
                self.end_headers()

            def do_GET(self):
                parsed = urlparse(self.path)
                path = parsed.path
                if path in ("/health", "/api/health"):
                    return self._json(200, {"ok": True, "service": app.name})
                fn = app.gets.get(path)
                if not fn:
                    return self._json(404, {"message": "Not found", "service": app.name})
                query = {k: v[0] for k, v in parse_qs(parsed.query).items()}
                code, payload = fn(query)
                return self._json(code, payload)

            def do_POST(self):
                parsed = urlparse(self.path)
                path = parsed.path
                length = int(self.headers.get("Content-Length") or 0)
                try:
                    payload = json.loads(self.rfile.read(length) or b"{}")
                except json.JSONDecodeError:
                    return self._json(400, {"message": "Request body must contain valid JSON."})
                if not isinstance(payload, dict):
                    return self._json(400, {"message": "Request body must be a JSON object."})
                fn = app.posts.get(path)
                if not fn:
                    return self._json(404, {"message": "Not found", "service": app.name})
                code, body = fn(payload)
                return self._json(code, body)

        print(f"{app.name} listening on {host}:{port}", flush=True)
        ThreadingHTTPServer((host, port), Handler).serve_forever()
