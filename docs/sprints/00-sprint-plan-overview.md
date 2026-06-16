# Enterprise Agentic RAG Platform (EARP) — Sprint Plan Overview

**Source of truth:** `docs/PRD.md`

This document divides the entire project described in the PRD into twelve implementation sprints. Every sprint scope item, acceptance criterion, service name, port, endpoint, and requirement ID is taken exclusively from the PRD.

---

## Product Context (PRD Section 1)

**Product Name:** Enterprise Agentic RAG Platform (EARP)

**Core Objective:** Architect and deploy a highly accurate, fully private, end-to-end multi-agent Retrieval-Augmented Generation system. The platform must autonomously ingest and process complex corporate data formats (including nested PDFs, dense financial charts, and SQL metadata), execute multi-step reasoning queries, and deliver verifiable answers. The system is mandated to maintain hallucination rates strictly below 5% through the use of iterative retrieval and aggressive output validation.

**Target Audience:** Internal corporate analysts, risk and compliance officers, and automated workflow orchestrators requiring highly secure, air-gapped access to proprietary data.

---

## User Personas (PRD Section 2)

| Persona | Responsibility |
|---|---|
| **System Administrator** | Manages Docker Compose environments, provisions LLM provider keys within the LiteLLM proxy, scales vLLM inference containers based on load, and monitors overall cluster health utilizing Prometheus and Grafana dashboards. |
| **Data Engineer** | Configures asynchronous ingestion pipelines, tunes Docling parsing schemas to capture specific table formats accurately, and defines rigid metadata access boundaries within the Qdrant database to secure sensitive documents. |
| **AI Developer** | Modifies LangGraph node logic, updates reasoning prompts, programs specialized Colang policies within NeMo Guardrails, and evaluates system performance via DeepEval CI/CD pipelines. |
| **End User (Analyst)** | Submits complex, multi-part natural language inquiries via the front-end user interface, expecting deterministic, highly cited outputs that trace back directly to uploaded source files. |

---

## 12-Layer Golden Tech Stack (PRD)

| Layer | Technology |
|---|---|
| 1 | Orchestration & Agents: LangGraph |
| 2 | LLM Backend: LiteLLM Gateway and vLLM Inference |
| 3 | Vector Database: Qdrant |
| 4 | Metadata and SQL Storage: PostgreSQL |
| 5 | Embeddings: Hugging Face Text Embeddings Inference (TEI) |
| 6 | Tracing and Observability: Langfuse |
| 7 | Evaluation: DeepEval |
| 8 | Metrics and Monitoring: Prometheus and Grafana (or Datadog) |
| 9 | Ingestion and Parsing: Docling |
| 10 | API Layer: FastAPI |
| 11 | Caching and Memory: Valkey and Mem0 |
| 12 | Guardrails: NeMo Guardrails |

---

## Sprint Roadmap

| Sprint | Title | PRD Sections | Functional Requirements |
|---|---|---|---|
| [Sprint 01](./sprint-01-docker-compose-foundation.md) | Docker Compose Foundation & Core Persistence | 12-Layer Stack (Layers 4, 11 partial), Docker Compose Network Topology Blueprint | — |
| [Sprint 02](./sprint-02-fastapi-api-gateway.md) | FastAPI API Gateway & JWT Authentication | 12-Layer Stack (Layer 10), Docker Compose (`api-gateway`) | — |
| [Sprint 03](./sprint-03-litellm-vllm.md) | LiteLLM Gateway & vLLM Inference | 12-Layer Stack (Layer 2), Docker Compose (`litellm-proxy`, `vllm-inference`) | FR-4 |
| [Sprint 04](./sprint-04-tei-qdrant-hybrid-search.md) | TEI Embeddings & Qdrant Hybrid Search | 12-Layer Stack (Layers 3, 5), Docker Compose (`tei-dense`, `tei-sparse`, `qdrant`), NFR Security and Privacy | FR-1 |
| [Sprint 05](./sprint-05-docling-ingestion.md) | Docling Ingestion & Asynchronous Processing | 12-Layer Stack (Layer 9), Docker Compose (`docling-api`, `docling-worker`) | FR-2 |
| [Sprint 06](./sprint-06-offline-ingestion-workflow.md) | Offline Ingestion Workflow & `/api/v1/ingest` | Section 3.1, Section 6 (`POST /api/v1/ingest`), NFR Scalability | FR-2 |
| [Sprint 07](./sprint-07-langgraph-orchestration.md) | LangGraph Agent Orchestration & State Persistence | 12-Layer Stack (Layer 1), Docker Compose (`api-gateway` LangGraph runtime) | FR-3 |
| [Sprint 08](./sprint-08-memory-caching.md) | Valkey Short-Term Caching & Mem0 Long-Term Memory | 12-Layer Stack (Layer 11) | — |
| [Sprint 09](./sprint-09-nemo-guardrails.md) | NeMo Guardrails | 12-Layer Stack (Layer 12), Docker Compose (`guardrails`) | FR-6 |
| [Sprint 10](./sprint-10-online-query-workflow.md) | Online Query Workflow & API Endpoints | Section 3.2, Section 6 (`POST /api/v1/ask`, `WS /api/v1/stream`), NFR Latency | — |
| [Sprint 11](./sprint-11-langfuse-observability.md) | Langfuse Tracing & Observability | 12-Layer Stack (Layer 6), Docker Compose (`langfuse-web`, `langfuse-worker`) | FR-5 |
| [Sprint 12](./sprint-12-evaluation-monitoring.md) | DeepEval CI Evaluation & Production Monitoring | 12-Layer Stack (Layers 7, 8), Section 7, NFR Accuracy, NFR Scalability, NFR Security and Privacy | — |

---

## Functional Requirements Traceability

| ID | Requirement | Sprint |
|---|---|---|
| FR-1 | Hybrid Vector Search | Sprint 04 |
| FR-2 | Document Parsing | Sprint 05, Sprint 06 |
| FR-3 | Stateful Agents | Sprint 07 |
| FR-4 | Routing and Fallbacks | Sprint 03 |
| FR-5 | LLM Observability | Sprint 11 |
| FR-6 | Programmatic Guardrails | Sprint 09 |

---

## Non-Functional Requirements Traceability

| NFR | Requirement | Sprint |
|---|---|---|
| Latency | TTFT within 2.5 seconds; conditional edges fast-path for simple queries | Sprint 10 |
| Accuracy | Hallucination rate ≤ 5% measured by DeepEval Faithfulness and Answer Relevancy on 1,000-question golden dataset | Sprint 12 |
| Scalability | High-volume concurrent ingestion via Docling worker pool and Valkey message broker | Sprint 05, Sprint 06, Sprint 12 |
| Security and Privacy | Document-scoped retrieval enforced at database level via Qdrant metadata filtering prior to RRF scoring | Sprint 04, Sprint 12 |

---

## Sprint Dependency Order

```
Sprint 01 (Foundation)
    ├── Sprint 02 (FastAPI)
    │       └── Sprint 07 (LangGraph)
    │               └── Sprint 08 (Memory)
    │                       └── Sprint 10 (Online Query) ← requires Sprint 09
    ├── Sprint 03 (LiteLLM / vLLM)
    ├── Sprint 04 (TEI / Qdrant)
    │       └── Sprint 06 (Ingestion Workflow) ← requires Sprint 05
    ├── Sprint 05 (Docling)
    ├── Sprint 09 (Guardrails)
    ├── Sprint 11 (Langfuse) ← requires Sprint 10
    └── Sprint 12 (Evaluation / Monitoring) ← requires all prior sprints
```

---

## Operational Lifecycles (PRD Section 3)

**Offline — Ingestion Workflow (Sprint 05, Sprint 06):**
Document Upload → Structural Parsing → Semantic Chunking → Parallel Embedding → Vector Indexing

**Online — Query and Agentic Retrieval Workflow (Sprint 07, Sprint 08, Sprint 09, Sprint 10, Sprint 11):**
Request Reception and Security → Strategic Planning → Tool Execution and Hybrid Search → Observation and Iteration → Synthesis and Citation → Fact-Checking → Delivery and Observability
