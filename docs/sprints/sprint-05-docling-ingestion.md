# Sprint 05 — Docling Ingestion & Asynchronous Processing

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layer 9), Docker Compose Network Topology Blueprint (`docling-api`, `docling-worker`), FR-2

**Depends on:** Sprint 01

**Primary persona:** Data Engineer

---

## Objective

Deploy Docling as the high-fidelity document parsing engine with horizontally scalable asynchronous processing via Valkey-backed RQ workers.

---

## Scope

### Docling API (`docling-api`)

| Property | Value (from PRD) |
|---|---|
| Docker Image | `quay.io/docling-project/docling-serve-cu128` |
| Port Mapping | `5001:5001` |
| Volume / State | `docling_data` volume |

**Responsibilities (from PRD):**

- Vision parsing, Table OCR, Markdown conversion.
- Submits jobs to RQ.
- Exposes a robust REST API.
- Operates entirely locally to ensure data privacy.

**Parsing capabilities (from PRD):**

- DocLayNet for complex layout analysis.
- TableFormer for robust table structure recognition.
- Achieve extreme accuracy on complex multi-column tables.
- Convert raw PDFs, Word documents, and PowerPoint presentations into semantically rich, LLM-friendly Markdown and JSON.
- Process visual structures seamlessly with layout-aware semantic reconstruction.
- Strictly preserve reading order and layout hierarchy.

### Docling Worker (`docling-worker`)

| Property | Value (from PRD) |
|---|---|
| Docker Image | `quay.io/docling-project/docling-serve-cu128` |
| Port Mapping | N/A |
| Volume / State | `docling_data` volume |

**Responsibilities (from PRD):**

- Scales horizontally to process asynchronous document queues via Valkey.
- Separate `docling-serve` rq-worker processes allowing ingestion workload to scale horizontally across multiple servers.

### Asynchronous Processing Configuration

- `DOCLING_SERVE_ENG_KIND` environment variable set to `rq` (Redis Queue) for production environments.
- Valkey or Redis message broker backing the RQ worker pool.

### FR-2 — Document Parsing

| Field | Value (from PRD) |
|---|---|
| **Feature Category** | Document Parsing |
| **Detailed Requirement** | The system must prevent data loss during the extraction of complex business documents. |
| **Acceptance Criteria** | `docling-serve` accurately parses multi-row, merged-cell tables and complex layouts into contiguous Markdown structures. |

### Docling Performance Reference (from PRD comparison table)

| Metric | Value |
|---|---|
| Table Extraction Accuracy | 97.9% accuracy. Perfect structural faithfulness. |
| Core Mechanism | AI Layout Analysis (DocLayNet, TableFormer). Semantic structure preservation. |
| Scalability | Linear scaling. Excellent balance of speed and precision. |

---

## Deliverables

1. `docling-api` container on port `5001:5001` with `docling_data` volume and REST API.
2. `docling-worker` container(s) scaling horizontally via Valkey-backed RQ.
3. `DOCLING_SERVE_ENG_KIND=rq` production configuration.
4. DocLayNet layout analysis and TableFormer table extraction producing Markdown and JSON output.

---

## Acceptance Criteria

- [ ] `docling-api` is deployed as `quay.io/docling-project/docling-serve-cu128` on port `5001:5001` with `docling_data` volume.
- [ ] `docling-worker` processes asynchronous document queues via Valkey message broker.
- [ ] `DOCLING_SERVE_ENG_KIND` is set to `rq` with separate rq-worker processes.
- [ ] **FR-2:** `docling-serve` accurately parses multi-row, merged-cell tables and complex layouts into contiguous Markdown structures.
- [ ] Parsing operates entirely locally for data privacy.

---

## Out of Scope (addressed in later sprints)

- FastAPI routing of uploads to Docling (Sprint 06)
- Semantic chunking after parsing (Sprint 06)
- Embedding and Qdrant indexing of parsed output (Sprint 06)
- NFR Scalability validation for bulk PDF uploads (Sprint 06, Sprint 12)
