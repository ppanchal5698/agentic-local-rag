# Sprint 12 — DeepEval CI Evaluation & Production Monitoring

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layers 7, 8), Section 7 (Evaluation and Lifecycle Management), NFR Accuracy, NFR Scalability, NFR Security and Privacy, NFR Latency

**Depends on:** All prior sprints (01–11)

**Primary personas:** AI Developer, System Administrator

---

## Objective

Establish continuous evaluation via DeepEval CI pipelines and production infrastructure monitoring via Prometheus/Grafana (or Datadog) to maintain operational health and accuracy across the deployed system.

---

## Scope

### DeepEval — Continuous Integration Evaluation (PRD Section 7)

**Framework purpose (from PRD):**

- Automated testing framework functioning similarly to Pytest, designed for validating non-deterministic LLM outputs using LLM-as-a-judge techniques.
- Continuous evaluation guarantees that modifications to the RAG platform do not silently degrade retrieval performance.

**Trigger conditions (from PRD):**

Before any code changes to the following are merged into the production branch, an automated DeepEval script executes:

- System prompt
- Retrieval hyper-parameters (such as adjusting the Top-K limit or the RRF smoothing constant)
- Semantic chunking strategies

**Evaluation dataset (from PRD):**

- Highly curated "golden dataset" of domain-specific questions.
- Baseline golden dataset of 1,000 highly complex industry questions.

**Metrics (from PRD):**

| Metric | Purpose |
|---|---|
| **Faithfulness** | Ensures the generated answer is strictly grounded in the retrieved chunks without external hallucinations. |
| **Answer Relevancy** | Verifies that the generated text actually addresses the original user prompt. |
| **Contextual Precision** | Ensures the vector database is surfacing the most valuable information at the top of the retrieval rankings. |
| **Contextual Relevancy** | Used as CI failure threshold metric. |

**CI pipeline behavior (from PRD):**

- Automatically fails the build if the Contextual Relevancy or Faithfulness scores drop below predetermined thresholds.

**Score destinations (from PRD):**

- Pushes scores into Confident AI, Langfuse, or Datadog.
- Appends quality metrics directly to production execution traces for long-term drift detection.

### NFR — Accuracy

- The systemic hallucination rate, measured continuously by DeepEval's Faithfulness and Answer Relevancy metrics, must remain ≤ 5% across a baseline golden dataset of 1,000 highly complex industry questions.

### Production Infrastructure Monitoring (PRD Section 7)

**Platforms (from PRD):**

- Prometheus and Grafana, or enterprise platforms like Datadog.

**Scope (from PRD):**

- Hardware and network infrastructure observability distinct from Langfuse semantic observability.
- Operating seamlessly in the background.
- Scrape the `/metrics` endpoints of all deployed Docker containers.

**Services exposing `/metrics` (from PRD):**

- vLLM
- LiteLLM
- TEI (Text Embeddings Inference)
- Qdrant

**Critical KPIs to monitor (from PRD):**

| KPI | Description |
|---|---|
| GPU VRAM utilization | Hardware resource consumption |
| `nim_batch_size_avg` | Average batch size of the inference engine |
| `nim_request_duration_p99` | 99th percentile request duration |
| Time-To-First-Token (TTFT) | Latency experienced by the end user |

**Deployment (from PRD):**

- Prometheus and Grafana deployed as lightweight Docker containers.
- Prometheus scrapes endpoints at defined intervals.
- Grafana visualizes time-series data.

**Automated alerts (from PRD):**

- Page the infrastructure team if inference degrades (e.g., vLLM `nim_request_duration_p99` exceeds safe limits).
- Page the infrastructure team if LangGraph orchestration nodes enter catastrophic infinite loops without generating safe checkpoints within PostgreSQL.

### NFR — Scalability (validation)

- The system must sustain high-volume concurrent ingestion queues without API degradation.
- The Docling worker pool must effectively integrate with the Valkey message broker to process bulk PDF uploads asynchronously across multiple container instances.

### NFR — Security and Privacy (validation)

- Document-scoped retrieval must be strictly enforced at the database level.
- A user querying the system must only receive vector chunks originating from documents they explicitly own or have Role-Based Access Control (RBAC) clearance to view.
- Qdrant metadata filtering must apply this restriction prior to RRF scoring.

### NFR — Latency (validation)

- The system must stream the first token (TTFT) to the client within 2.5 seconds.
- For explicitly simple queries, conditional edges must bypass the reasoning loop entirely as a fast-path generator.

---

## Deliverables

1. Automated DeepEval script evaluating Faithfulness, Answer Relevancy, Contextual Precision, and Contextual Relevancy.
2. CI pipeline failing builds when Contextual Relevancy or Faithfulness scores drop below predetermined thresholds.
3. Golden dataset of 1,000 highly complex industry questions.
4. DeepEval score push to Confident AI, Langfuse, or Datadog.
5. Prometheus container scraping `/metrics` from vLLM, LiteLLM, TEI, and Qdrant.
6. Grafana container visualizing time-series KPI data.
7. Automated alerts for inference degradation and LangGraph infinite loops without PostgreSQL checkpoints.
8. NFR validation: hallucination rate ≤ 5%, TTFT ≤ 2.5 seconds, ingestion scalability, ACL enforcement.

---

## Acceptance Criteria

- [ ] DeepEval CI script executes automatically before merging changes to system prompt, retrieval hyper-parameters, or semantic chunking strategies.
- [ ] CI pipeline fails if Contextual Relevancy or Faithfulness scores drop below predetermined thresholds.
- [ ] Evaluation runs against golden dataset of 1,000 highly complex industry questions.
- [ ] DeepEval measures Faithfulness, Answer Relevancy, and Contextual Precision.
- [ ] Scores are pushed to Confident AI, Langfuse, or Datadog.
- [ ] **NFR Accuracy:** Systemic hallucination rate remains ≤ 5% measured by DeepEval Faithfulness and Answer Relevancy metrics.
- [ ] Prometheus scrapes `/metrics` endpoints from vLLM, LiteLLM, TEI, and Qdrant Docker containers.
- [ ] Grafana visualizes GPU VRAM utilization, `nim_batch_size_avg`, `nim_request_duration_p99`, and TTFT.
- [ ] Automated alerts page infrastructure team when vLLM `nim_request_duration_p99` exceeds safe limits.
- [ ] Automated alerts page infrastructure team when LangGraph nodes enter infinite loops without PostgreSQL checkpoints.
- [ ] **NFR Scalability:** High-volume concurrent ingestion queues are sustained without API degradation via Docling worker pool and Valkey broker.
- [ ] **NFR Security and Privacy:** Users only receive vector chunks from documents they own or have RBAC clearance for; Qdrant metadata filtering applies prior to RRF scoring.
- [ ] **NFR Latency:** TTFT is within 2.5 seconds; conditional edges bypass reasoning loop for simple queries.

---

## Out of Scope

This is the final sprint. All PRD-defined capabilities are addressed across Sprints 01–12.
