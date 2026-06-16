#!/usr/bin/env bash
# Sprint 01 acceptance verification for EARP foundation stack.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

RUN_GPU_TEST=false
if [[ "${1:-}" == "--gpu" ]]; then
  RUN_GPU_TEST=true
fi

if [[ ! -f .env ]]; then
  echo "Creating .env from .env.example"
  cp .env.example .env
fi

# shellcheck disable=SC1091
source .env

POSTGRES_PORT="${POSTGRES_PORT:-5432}"
VALKEY_PORT="${VALKEY_PORT:-6379}"
POSTGRES_USER="${POSTGRES_USER:-earp}"
POSTGRES_DB="${POSTGRES_DB:-earp}"

pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; exit 1; }

container_health() {
  docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$1" 2>/dev/null || true
}

wait_healthy() {
  local name="$1"
  local timeout="${2:-120}"
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

echo "==> Starting stack"
docker compose up -d || fail "docker compose up failed (image pull or startup error)"

echo "==> Waiting for healthy services (up to 120s)"
wait_healthy earp-postgres 120 || fail "postgres not healthy (status=$(container_health earp-postgres))"
wait_healthy earp-valkey 120 || fail "valkey not healthy (status=$(container_health earp-valkey))"
pass "postgres and valkey are healthy"

echo "==> Checking rag-net membership"
network_containers="$(docker network inspect rag-net --format '{{range .Containers}}{{.Name}} {{end}}')"
echo "    containers on rag-net: ${network_containers}"
[[ "${network_containers}" == *"earp-postgres"* ]] || fail "postgres not on rag-net"
[[ "${network_containers}" == *"earp-valkey"* ]] || fail "valkey not on rag-net"
pass "both services attached to rag-net"

echo "==> Checking inter-container connectivity"
valkey_host="$(docker compose exec -T postgres getent hosts valkey | tr -d '[:space:]')"
[[ -n "${valkey_host}" ]] || fail "postgres cannot resolve valkey on rag-net"
pass "postgres can resolve valkey on rag-net"

echo "==> Checking Valkey reachability on localhost:${VALKEY_PORT}"
pong="$(docker compose exec -T valkey valkey-cli ping)"
[[ "${pong}" == "PONG" ]] || fail "valkey ping expected PONG, got ${pong}"
pass "valkey-cli ping returned PONG"

echo "==> PostgreSQL persistence test"
docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c \
  "CREATE TABLE IF NOT EXISTS sprint01_check (id serial PRIMARY KEY, note text); TRUNCATE sprint01_check; INSERT INTO sprint01_check (note) VALUES ('persist');"
docker compose restart postgres > /dev/null
sleep 5
wait_healthy earp-postgres 60 || fail "postgres did not become healthy after restart"
pg_row="$(docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT note FROM sprint01_check LIMIT 1;")"
pg_row="$(echo "${pg_row}" | tr -d '[:space:]')"
[[ "${pg_row}" == "persist" ]] || fail "postgres data lost after restart (got '${pg_row}')"
pass "postgres data persisted across restart"

echo "==> Valkey persistence test"
docker compose exec -T valkey valkey-cli SET sprint01 persist > /dev/null
docker compose restart valkey > /dev/null
sleep 5
wait_healthy earp-valkey 60 || fail "valkey did not become healthy after restart"
vk_val="$(docker compose exec -T valkey valkey-cli GET sprint01)"
vk_val="$(echo "${vk_val}" | tr -d '[:space:]')"
[[ "${vk_val}" == "persist" ]] || fail "valkey data lost after restart (got '${vk_val}')"
pass "valkey data persisted across restart"

if [[ "${RUN_GPU_TEST}" == true ]]; then
  echo "==> GPU smoke test"
  if docker compose -f docker-compose.yml -f docker-compose.gpu.yml --profile gpu-test run --rm gpu-smoke-test nvidia-smi; then
    pass "gpu-smoke-test nvidia-smi succeeded"
  else
    fail "gpu-smoke-test nvidia-smi failed"
  fi
else
  echo "==> Skipping GPU smoke test (pass --gpu to run)"
fi

echo ""
echo "Sprint 01 verification complete."
