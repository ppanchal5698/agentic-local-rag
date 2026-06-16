# Sprint 01 — Docker Compose Foundation & Core Persistence

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layers 4, 11 partial), Docker Compose Network Topology Blueprint, Hardware Allocation Note

**Depends on:** None (first sprint)

**Primary persona:** System Administrator

---

## Objective

Deploy the foundational Docker Compose infrastructure and core persistence services that all other microservices depend on.

---

## Scope

### Docker Network

- Isolate all services within an internal bridged Docker network (e.g., `rag-net`).

### PostgreSQL (`postgres`)

| Property | Value (from PRD) |
|---|---|
| Docker Image | `postgres:16` |
| Port Mapping | `5432:5432` |
| Volume | `pgdata` volume |

**Core responsibilities (from PRD):**

- LangGraph checkpointer (PostgresSaver / AsyncPostgresSaver) — writes every intermediate agent state, tool call, and scratchpad memory to disk.
- Primary storage backend for the Langfuse observability platform — holds hierarchical trace spans, evaluation scores, and token consumption metrics.
- Storage backend for the LiteLLM gateway — tracks virtual API keys, spend limits, and programmatic access controls.
- Document metadata and Access Control Lists (ACLs) — ensures document-scoped retrieval strictly prevents cross-document data leakage between unauthorized users.

**Version requirement:** PostgreSQL version 14 or higher.

### Valkey (`valkey`)

| Property | Value (from PRD) |
|---|---|
| Docker Image | `valkey/valkey:latest` |
| Port Mapping | `6379:6379` |
| Volume | `valkey_data` volume |

**Core responsibilities (from PRD):**

- Ephemeral caching and session scratchpads.
- Distributed queue brokering for workers.
- Message broker for RQ background job queues powering Docling asynchronous document processing.
- In-session memory, scratchpad state, fast tool call lookups, and duplicate request caching (full application memory usage defined in Sprint 08).

### Hardware Allocation

Services designated with GPU requirements must be configured in `docker-compose.yml` using `deploy.resources.reservations.devices` specifying NVIDIA runtime drivers to allow bare-metal VRAM access.

---

## Deliverables

1. `docker-compose.yml` with `rag-net` bridged network.
2. `postgres` service running on port `5432` with `pgdata` volume persistence.
3. `valkey` service running on port `6379` with `valkey_data` volume persistence.
4. GPU reservation configuration pattern in `docker-compose.yml` for services requiring NVIDIA runtime drivers.

---

## Acceptance Criteria

- [x] All services communicate over the internal bridged Docker network (`rag-net`).
- [x] PostgreSQL (version 14 or higher) persists data to the `pgdata` volume across container restarts.
- [x] Valkey persists data to the `valkey_data` volume and is reachable on port `6379`.
- [x] `deploy.resources.reservations.devices` NVIDIA runtime configuration is present for GPU-designated services.

---

## Out of Scope (addressed in later sprints)

- FastAPI `api-gateway` (Sprint 02)
- LiteLLM, vLLM, TEI, Qdrant, Docling, Langfuse, Guardrails containers (Sprints 03–05, 09, 11)
- Application-level ACL logic (Sprint 04, Sprint 06)
- LangGraph checkpointer integration (Sprint 07)
- Langfuse and LiteLLM PostgreSQL schema usage (Sprints 03, 11)
