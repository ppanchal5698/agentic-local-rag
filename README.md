# Enterprise Agentic RAG Platform (EARP)

Production-grade Agentic RAG stack defined in [`docs/PRD.md`](docs/PRD.md). Implementation is tracked sprint-by-sprint in [`docs/sprints/00-sprint-plan-overview.md`](docs/sprints/00-sprint-plan-overview.md).

## Current sprint status

| Sprint | Title | Status |
|--------|-------|--------|
| 01 | Docker Compose Foundation & Core Persistence | Complete |
| 02 | FastAPI API Gateway & JWT Authentication | Complete |

## Prerequisites

1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) with WSL2 backend
2. NVIDIA drivers + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) in WSL2 (for GPU services in later sprints)
3. [uv](https://docs.astral.sh/uv/) for Python dependency management
4. Docker Compose v2 (`docker compose`)

## Quick start

```bash
# Copy environment template and set credentials
cp .env.example .env

# Start full stack (postgres, valkey, api-gateway)
docker compose up -d --build

# Run acceptance checks
.\scripts\verify-sprint02.ps1     # Windows PowerShell
# or
./scripts/verify-sprint02.sh      # POSIX
```

Sprint 01-only verification (persistence layer):

```bash
.\scripts\verify-sprint01.ps1
.\scripts\verify-sprint01.ps1 -Gpu   # optional GPU smoke test
```

## API gateway (Sprint 02)

The `api-gateway` service runs at `http://localhost:8000` on `rag-net`.

### Obtain a dev JWT

```bash
curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"sub":"analyst-1","permissions":["ingest:write","query:read"]}'
```

### Call protected endpoints

```bash
TOKEN="<access_token from above>"

curl -s http://localhost:8000/api/v1/me \
  -H "Authorization: Bearer $TOKEN"

curl -s http://localhost:8000/api/v1/health/deps \
  -H "Authorization: Bearer $TOKEN"
```

Dev token issuance is only enabled when `ENVIRONMENT=development`.

## Repository layout

```
├── docker-compose.yml              # postgres, valkey, api-gateway
├── docker-compose.gpu.yml          # GPU reservation pattern + smoke test
├── services/api-gateway/           # FastAPI application
├── infra/                          # Volume and port reference
├── scripts/                        # Verification scripts
└── docs/                           # PRD and sprint plans
```

## What's next (Sprint 03)

- `litellm-proxy` on port `4000`
- `vllm-inference` on port `8001` with GPU passthrough
- Unified OpenAI-compatible LLM routing
