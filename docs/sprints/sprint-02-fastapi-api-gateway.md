# Sprint 02 — FastAPI API Gateway & JWT Authentication

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layer 10), Docker Compose Network Topology Blueprint (`api-gateway`)

**Depends on:** Sprint 01

**Primary persona:** AI Developer, System Administrator

---

## Objective

Deploy the FastAPI entry point that binds orchestration graphs, ingestion pipelines, and user-facing client interfaces, with JWT-based security validation.

---

## Scope

### `api-gateway` Service

| Property | Value (from PRD) |
|---|---|
| Docker Image | `fastapi-app:latest` |
| Port Mapping | `8000:8000` |
| Volume / State | Application code, `.env` files |

### FastAPI Responsibilities (from PRD)

- Represent the entry point into the system.
- Provide a high-performance, asynchronous REST architecture designed to handle concurrent I/O operations without blocking.
- Manage security by validating JSON Web Tokens (JWT) to establish the user's identity and permissions.
- Route binary document payloads to the Docling ingestion container (integration in Sprint 06).
- Initialize the LangGraph state machine when receiving a query (integration in Sprint 07).
- Utilize WebSockets or Server-Sent Events (SSE) to stream partial tokens and intermediate agent actions (the "thoughts" and "tool calls") back to the user interface in real-time (integration in Sprint 10).

### LangGraph Runtime

- The LangGraph framework executes within the FastAPI Docker container, scaling horizontally while session states are centrally managed.

---

## Deliverables

1. `api-gateway` FastAPI Docker container on port `8000`.
2. JWT authentication middleware validating user identity and permissions.
3. Asynchronous REST architecture foundation.
4. WebSocket/SSE capability foundation for real-time streaming (endpoint implementation in Sprint 10).

---

## Acceptance Criteria

- [x] `api-gateway` service is deployed as `fastapi-app:latest` on port `8000:8000` within `rag-net`.
- [x] JWT credentials are validated to establish user identity and permissions on protected endpoints.
- [x] FastAPI handles concurrent I/O operations asynchronously without blocking.
- [x] Application code and `.env` files are mounted as specified.

---

## Out of Scope (addressed in later sprints)

- `POST /api/v1/ingest` endpoint (Sprint 06)
- `POST /api/v1/ask` endpoint (Sprint 10)
- `WS /api/v1/stream` endpoint (Sprint 10)
- LangGraph state machine initialization (Sprint 07)
- Document routing to Docling (Sprint 06)
- NeMo Guardrails interception (Sprint 09)
