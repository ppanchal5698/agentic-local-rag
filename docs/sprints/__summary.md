Sprint Plan Summary
13 files in docs/sprints/:

File	Sprint	PRD Coverage
00-sprint-plan-overview.md
Master plan
Sections 1–3, 12-layer stack, FR/NFR traceability, dependencies
sprint-01-docker-compose-foundation.md
Foundation
rag-net, PostgreSQL, Valkey, GPU config
sprint-02-fastapi-api-gateway.md
API Gateway
Layer 10, JWT, api-gateway
sprint-03-litellm-vllm.md
LLM Backend
Layer 2, litellm-proxy, vllm-inference, FR-4
sprint-04-tei-qdrant-hybrid-search.md
Embeddings & Vector DB
Layers 3 & 5, RRF, ACL filtering, FR-1
sprint-05-docling-ingestion.md
Docling
Layer 9, docling-api, docling-worker, FR-2
sprint-06-offline-ingestion-workflow.md
Ingestion Pipeline
Section 3.1, POST /api/v1/ingest
sprint-07-langgraph-orchestration.md
LangGraph
Layer 1, PostgresSaver, FR-3
sprint-08-memory-caching.md
Memory
Layer 11, Valkey + Mem0
sprint-09-nemo-guardrails.md
Guardrails
Layer 12, Colang, AlignScore, FR-6
sprint-10-online-query-workflow.md
Query Workflow
Section 3.2, POST /api/v1/ask, WS /api/v1/stream, TTFT NFR
sprint-11-langfuse-observability.md
Observability
Layer 6, langfuse-web, langfuse-worker, FR-5
sprint-12-evaluation-monitoring.md
Evaluation & Monitoring
Layers 7 & 8, DeepEval CI, Prometheus/Grafana, all NFRs
Dependency Order
01 → 02, 03, 04, 05, 09
04 + 05 + 02 → 06
02 + 03 → 07 → 08
02 + 03 + 04 + 06 + 07 + 08 + 09 → 10 → 11 → 12
Each sprint file includes:

Exact PRD section references
Service names, images, ports, and volumes from the Docker Compose blueprint
Functional requirement IDs and acceptance criteria verbatim from the PRD
Deliverables and checkboxes mapped to PRD acceptance criteria only
Explicit out-of-scope items pointing to the sprint that owns them
Start with docs/sprints/00-sprint-plan-overview.md for the full traceability matrix.