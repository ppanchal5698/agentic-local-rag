#!/usr/bin/env bash
# Sprint 02 acceptance verification for EARP API gateway.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

if [[ ! -f .env ]]; then
  echo "Creating .env from .env.example"
  cp .env.example .env
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

API_PORT="${API_GATEWAY_PORT:-8000}"
BASE_URL="http://localhost:${API_PORT}"

pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; exit 1; }

container_health() {
  docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$1" 2>/dev/null || true
}

wait_healthy() {
  local name="$1"
  local timeout="${2:-180}"
  local deadline=$((SECONDS + timeout))
  while (( SECONDS < deadline )); do
    local health
    health="$(container_health "${name}")"
    if [[ "${health}" == "healthy" ]]; then
      return 0
    fi
    sleep 2
  done
  return 1
}

echo "==> Building and starting stack"
docker compose up -d --build || fail "docker compose up --build failed"

echo "==> Waiting for api-gateway to become healthy"
wait_healthy earp-api-gateway 180 || fail "api-gateway not healthy (status=$(container_health earp-api-gateway))"
pass "api-gateway is healthy"

echo "==> Checking rag-net membership"
network_containers="$(docker network inspect rag-net --format '{{range .Containers}}{{.Name}} {{end}}')"
[[ "${network_containers}" == *"earp-api-gateway"* ]] || fail "api-gateway not on rag-net"
pass "api-gateway attached to rag-net"

echo "==> GET /health"
health="$(curl -sf "${BASE_URL}/health")"
[[ "${health}" == *"ok"* ]] || fail "/health returned unexpected payload"
pass "/health returned 200"

echo "==> GET /api/v1/me without token (expect 401)"
status="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/api/v1/me")"
[[ "${status}" == "401" ]] || fail "expected 401 without token, got ${status}"
pass "protected endpoint rejected unauthenticated request"

echo "==> POST /api/v1/auth/token"
token_response="$(curl -sf -X POST "${BASE_URL}/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"sub":"verify-user","permissions":["ingest:write","query:read"]}')"
token="$(echo "${token_response}" | python -c "import json,sys; print(json.load(sys.stdin)['access_token'])")"
[[ -n "${token}" ]] || fail "token endpoint did not return access_token"
pass "obtained dev JWT"

echo "==> GET /api/v1/me with token"
me="$(curl -sf "${BASE_URL}/api/v1/me" -H "Authorization: Bearer ${token}")"
[[ "${me}" == *"verify-user"* ]] || fail "/api/v1/me returned wrong identity"
pass "/api/v1/me returned identity and permissions"

echo "==> GET /api/v1/health/deps with token"
deps="$(curl -sf "${BASE_URL}/api/v1/health/deps" -H "Authorization: Bearer ${token}")"
[[ "${deps}" == *'"postgres"'* && "${deps}" == *'"ok"'* ]] || fail "postgres probe failed"
[[ "${deps}" == *'"valkey"'* ]] || fail "valkey probe missing"
pass "async dependency probes succeeded"

echo "==> Parallel async probe test (10 concurrent requests)"
pids=()
for _ in $(seq 1 10); do
  curl -sf "${BASE_URL}/api/v1/health/deps" -H "Authorization: Bearer ${token}" > /dev/null &
  pids+=($!)
done
for pid in "${pids[@]}"; do
  wait "${pid}" || fail "concurrent request failed"
done
pass "10 concurrent async requests succeeded"

echo "==> WebSocket stub test"
docker compose exec -T api-gateway uv run python -m app.ws_smoke_test "${token}" || fail "websocket stub test failed"
pass "websocket stub returned connected status"

echo "==> SSE stub test"
sse="$(curl -sf "${BASE_URL}/api/v1/events?token=${token}")"
[[ "${sse}" == *"connected"* ]] || fail "SSE stream missing connected event"
pass "SSE stub streamed status events"

echo ""
echo "Sprint 02 verification complete."
