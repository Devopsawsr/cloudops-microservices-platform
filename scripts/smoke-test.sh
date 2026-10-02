#!/usr/bin/env bash
set -euo pipefail

base_url="${BASE_URL:-http://localhost:8080}"
email="smoke-$(date +%s)@example.com"

expect_ok() {
  name="$1"
  path="$2"
  code="$(curl -sS -o /tmp/cloudops-smoke-body -w '%{http_code}' --max-time 10 "${base_url}${path}")"
  if [[ "${code}" != "200" ]]; then
    echo "FAIL ${name}: HTTP ${code}"
    cat /tmp/cloudops-smoke-body
    exit 1
  fi
  echo "PASS ${name}"
}

expect_ok "gateway health" "/api/health"
expect_ok "catalog" "/api/books"
expect_ok "labs" "/api/labs"

signup_code="$(curl -sS -o /tmp/cloudops-smoke-body -w '%{http_code}' --max-time 10 \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"Smoke Test\",\"email\":\"${email}\",\"password\":\"Test123\"}" \
  "${base_url}/api/signup")"
[[ "${signup_code}" == "201" ]] || { echo "FAIL signup: HTTP ${signup_code}"; cat /tmp/cloudops-smoke-body; exit 1; }
echo "PASS signup"

exam_code="$(curl -sS -o /tmp/cloudops-smoke-body -w '%{http_code}' --max-time 10 \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"Smoke Test\",\"email\":\"${email}\",\"book_id\":\"terraform\",\"score\":85}" \
  "${base_url}/api/exam")"
[[ "${exam_code}" == "200" ]] || { echo "FAIL exam: HTTP ${exam_code}"; cat /tmp/cloudops-smoke-body; exit 1; }
echo "PASS exam and certificate workflow"

expect_ok "certificates" "/api/certificates"
expect_ok "leaderboard" "/api/leaderboard"
echo "All smoke tests passed."
