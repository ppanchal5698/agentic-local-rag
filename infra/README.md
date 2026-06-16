# Infrastructure

Sprint 01 persistence layer for the Enterprise Agentic RAG Platform (EARP).

## Services

| Service  | Image                  | Host port (default) | Internal DNS | Volume      |
|----------|------------------------|---------------------|--------------|-------------|
| postgres | `postgres:16`          | 5432                | `postgres`   | `pgdata`    |
| valkey   | `valkey/valkey:latest` | 6379                | `valkey`     | `valkey_data` |

All services attach to the `rag-net` bridge network. Future containers reach PostgreSQL at `postgres:5432` and Valkey at `valkey:6379`.

## PostgreSQL roles (future sprints)

Per the PRD, PostgreSQL will eventually host:

- LangGraph checkpointer state (Sprint 07)
- Langfuse trace storage (Sprint 11)
- LiteLLM virtual keys and spend tracking (Sprint 03)
- Document metadata and ACLs (Sprint 04, Sprint 06)

Init SQL scripts for application schemas will be added under `infra/postgres/` as those sprints land.

## GPU services

GPU reservation patterns live in [`docker-compose.gpu.yml`](../docker-compose.gpu.yml). Sprint 03+ services (vLLM, TEI, Docling) will extend the shared `x-gpu-deploy` anchor.
