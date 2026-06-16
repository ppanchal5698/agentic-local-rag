# Enterprise Agentic RAG Platform (EARP)

Production-grade Agentic RAG stack defined in [`docs/PRD.md`](docs/PRD.md). Implementation is tracked sprint-by-sprint in [`docs/sprints/00-sprint-plan-overview.md`](docs/sprints/00-sprint-plan-overview.md).

## Current sprint status

| Sprint | Title | Status |
|--------|-------|--------|
| 01 | Docker Compose Foundation & Core Persistence | Complete |
| 02 | FastAPI API Gateway & JWT Authentication | Planned |

## Prerequisites

1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) with WSL2 backend
2. NVIDIA drivers + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) in WSL2 (for GPU services in later sprints)
3. [uv](https://docs.astral.sh/uv/) for Python dependency management (Sprint 02+)
4. Docker Compose v2 (`docker compose`)

Verify GPU passthrough:

```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

## Quick start (Sprint 01)

```bash
# Copy environment template and set credentials
cp .env.example .env

# Start core persistence services
docker compose up -d

# Run acceptance checks
./scripts/verify-sprint01.sh        # POSIX
# or
.\scripts\verify-sprint01.ps1     # Windows PowerShell
```

Optional GPU smoke test:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml --profile gpu-test run --rm gpu-smoke-test nvidia-smi
```

## Sprint dependency order

```
Sprint 01 (Foundation)
    ├── Sprint 02 (FastAPI)
    ├── Sprint 03 (LiteLLM / vLLM)
    ├── Sprint 04 (TEI / Qdrant)
    ├── Sprint 05 (Docling)
    └── Sprint 09 (Guardrails)
```

See the full dependency graph in [`docs/sprints/00-sprint-plan-overview.md`](docs/sprints/00-sprint-plan-overview.md).

## Repository layout

```
├── docker-compose.yml          # Base stack (postgres, valkey)
├── docker-compose.gpu.yml      # GPU reservation pattern + smoke test
├── infra/                      # Volume and port reference
├── services/                   # Microservice code (Sprint 02+)
├── scripts/                    # Verification scripts
└── docs/                       # PRD and sprint plans
```

## What's next (Sprint 02)

- `api-gateway` FastAPI container on port `8000`
- JWT authentication middleware
- Async REST foundation for LangGraph and ingestion endpoints
