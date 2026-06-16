# Sprint 06 — Offline Ingestion Workflow & `/api/v1/ingest`

**Source of truth:** `docs/PRD.md`

**PRD references:** Section 3.1 (Ingestion Workflow), Section 6 (`POST /api/v1/ingest`), FR-2, NFR Scalability

**Depends on:** Sprint 01, Sprint 02, Sprint 04, Sprint 05

**Primary persona:** Data Engineer, End User (Analyst)

---

## Objective

Implement the complete offline data ingestion lifecycle from document upload through vector indexing, exposed via the `POST /api/v1/ingest` API endpoint.

---

## Scope

### Ingestion Workflow (PRD Section 3.1)

#### Step 1 — Document Upload

- The user uploads a visually dense, multi-page PDF via the FastAPI `/api/v1/ingest` endpoint.
- The API verifies the user's JWT credentials.
- The API writes the document's Access Control List (ACL) metadata to PostgreSQL.

#### Step 2 — Structural Parsing

- FastAPI queues the binary file to the `docling-worker` pool via Valkey.
- Operating asynchronously, Docling applies TableFormer and DocLayNet to parse tables, extract textual paragraphs, and strictly preserve the reading order and layout hierarchy, outputting standard Markdown.

#### Step 3 — Semantic Chunking

- The resulting Markdown is processed by a chunking algorithm.
- Unlike primitive character-splitting, this step chunks the document semantically.
- Preserves structural metadata such as headers and page numbers within each segment.

#### Step 4 — Parallel Embedding

- The raw text chunks are routed simultaneously to the `tei-dense` container (generating semantic vectors) and the `tei-sparse` container (generating BM25 token frequencies).

#### Step 5 — Vector Indexing

- The resulting dense and sparse arrays, combined with the document's exact access metadata, are upserted into the Qdrant vector database.
- The system marks the document as fully indexed in PostgreSQL, completing the pipeline.

### API Specification — `POST /api/v1/ingest`

| Field | Value (from PRD) |
|---|---|
| **Method** | POST |
| **Path** | `/api/v1/ingest` |
| **Request Configuration** | `multipart/form-data` (File types: PDF, DOCX, PPTX), accompanied by a `metadata: dict` specifying organizational access policies. |
| **Response Configuration** | Returns `202 Accepted` with a tracking payload: `{ "job_id": "uuid", "status": "processing" }`. |

**Endpoint responsibilities (from PRD):**

- Accepts multipart file uploads.
- Extracts security metadata.
- Dispatches the processing payload to Docling, effectively queuing the embedding workloads.

### NFR — Scalability (ingestion-specific)

- The system must sustain high-volume concurrent ingestion queues without API degradation.
- The Docling worker pool must effectively integrate with the Valkey message broker to process bulk PDF uploads asynchronously across multiple container instances.

### FR-2 — Document Parsing (end-to-end validation)

| Field | Value (from PRD) |
|---|---|
| **Acceptance Criteria** | `docling-serve` accurately parses multi-row, merged-cell tables and complex layouts into contiguous Markdown structures. |

---

## Deliverables

1. `POST /api/v1/ingest` endpoint accepting PDF, DOCX, PPTX with `metadata: dict` access policies.
2. JWT credential verification on ingest requests.
3. ACL metadata persistence to PostgreSQL.
4. Asynchronous queuing of binary files to `docling-worker` pool via Valkey.
5. Semantic chunking preserving headers and page numbers.
6. Parallel routing of chunks to `tei-dense` and `tei-sparse`.
7. Qdrant upsert of dense and sparse arrays with access metadata.
8. Document indexed status marking in PostgreSQL.
9. `202 Accepted` response with `{ "job_id": "uuid", "status": "processing" }`.

---

## Acceptance Criteria

- [ ] `POST /api/v1/ingest` accepts `multipart/form-data` uploads of PDF, DOCX, and PPTX with `metadata: dict` access policies.
- [ ] JWT credentials are verified and ACL metadata is written to PostgreSQL.
- [ ] Binary files are queued to `docling-worker` via Valkey asynchronously.
- [ ] Docling outputs Markdown with preserved reading order, layout hierarchy, headers, and page numbers.
- [ ] Semantic chunking preserves structural metadata within each segment.
- [ ] Chunks are embedded in parallel via `tei-dense` and `tei-sparse`.
- [ ] Dense and sparse vectors with access metadata are upserted into Qdrant.
- [ ] Document is marked as fully indexed in PostgreSQL upon completion.
- [ ] Endpoint returns `202 Accepted` with `{ "job_id": "uuid", "status": "processing" }`.
- [ ] **FR-2:** Multi-row, merged-cell tables and complex layouts are parsed into contiguous Markdown structures.
- [ ] Docling worker pool processes bulk PDF uploads asynchronously across multiple container instances via Valkey.

---

## Out of Scope (addressed in later sprints)

- Query-time retrieval from Qdrant (Sprint 10)
- NeMo Guardrails on ingest path (not specified in PRD for ingest)
- Langfuse tracing of ingestion (Sprint 11)
- DeepEval evaluation of ingestion quality (Sprint 12)
