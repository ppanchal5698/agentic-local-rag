# Infrastructure

Sprint 01–02 persistence and API layer for the Enterprise Agentic RAG Platform (EARP).

## Services

| Service      | Image                  | Host port (default) | Internal DNS  | Volume / mount        |
|--------------|------------------------|---------------------|---------------|-----------------------|
| postgres     | `postgres:16`          | 5432                | `postgres`    | `pgdata`              |
| valkey       | `valkey/valkey:latest` | 6379                | `valkey`      | `valkey_data`         |
| api-gateway  | `fastapi-app:latest`   | 8000                | `api-gateway` | `./services/api-gateway/app` |

All services attach to the `rag-net` bridge network.

## PostgreSQL roles (future sprints)

Per the PRD, PostgreSQL will eventually host:

- LangGraph checkpointer state (Sprint 07)
- Langfuse trace storage (Sprint 11)
- LiteLLM virtual keys and spend tracking (Sprint 03)
- Document metadata and ACLs (Sprint 04, Sprint 06)

Init SQL scripts for application schemas will be added under `infra/postgres/` as those sprints land.

## GPU services

GPU reservation patterns live in [`docker-compose.gpu.yml`](../docker-compose.gpu.yml). Sprint 03+ services (vLLM, TEI, Docling) will extend the shared `x-gpu-deploy` anchor.
