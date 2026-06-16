# EARP API Gateway

FastAPI entry point for the Enterprise Agentic RAG Platform.

## Local development

```bash
cd services/api-gateway
uv sync
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Requires a `.env` at the repository root (or export `JWT_SECRET`).

## Sprint 02 endpoints

| Method | Path | Auth |
|--------|------|------|
| GET | `/health` | Public |
| GET | `/api/v1/health` | Public |
| GET | `/api/v1/health/deps` | Bearer JWT |
| GET | `/api/v1/me` | Bearer JWT |
| POST | `/api/v1/auth/token` | Dev only |
| WS | `/api/v1/stream?token=` | JWT query param |
| GET | `/api/v1/events?token=` | JWT query param (SSE) |
