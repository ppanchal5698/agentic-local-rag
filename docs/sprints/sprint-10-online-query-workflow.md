# Sprint 10 — Online Query Workflow & API Endpoints

**Source of truth:** `docs/PRD.md`

**PRD references:** Section 3.2 (Query and Agentic Retrieval Workflow), Section 6 (`POST /api/v1/ask`, `WS /api/v1/stream`), NFR Latency

**Depends on:** Sprint 02, Sprint 03, Sprint 04, Sprint 06, Sprint 07, Sprint 08, Sprint 09

**Primary persona:** End User (Analyst), AI Developer

---

## Objective

Implement the complete online ReAct agentic retrieval workflow with iterative search, citation synthesis, and real-time streaming via REST and WebSocket API endpoints.

---

## Scope

### Query and Agentic Retrieval Workflow (PRD Section 3.2)

#### Step 1 — Request Reception and Security

- The user submits a natural language question to the `/api/v1/ask` endpoint.
- The prompt is immediately routed through NeMo Guardrails.
- If the input contains a recognized jailbreak heuristic or violates topical boundaries, the request is instantly rejected.

#### Step 2 — Strategic Planning

- Assuming the prompt is safe, the primary LangGraph RAG agent receives the query.
- The agent accesses Mem0 to retrieve relevant short-term and long-term conversation history.
- The agent formulates a multi-step retrieval plan, defining exactly what data it needs to extract.

#### Step 3 — Tool Execution and Hybrid Search

- The agent executes a tool call targeting Qdrant.
- The database receives the query and executes a hybrid search, applying Reciprocal Rank Fusion (RRF) to merge the results of the dense semantic matches and the sparse lexical matches.
- It returns the top-K chunks that strictly match the user's ACL metadata.

#### Step 4 — Observation and Iteration

- The agent observes the returned chunks.
- If the context is deemed insufficient, contradictory, or empty, the agent reformulates its search terms and re-queries the database.
- The agent refuses to push poor context to the generation step.

#### Step 5 — Synthesis and Citation

- Once satisfied with the context, the agent synthesizes the final response.
- It embeds explicit citations directly into the text, mapping claims to the specific `doc_id` and page number of the source chunk.

#### Step 6 — Fact-Checking

- The generated synthesis is intercepted by NeMo Guardrails' output rails.
- The AlignScore model cross-references the generated text against the originally retrieved chunks.
- If the model detects ungrounded hallucination, the output is blocked and the agent is forced to regenerate.

#### Step 7 — Delivery and Observability

- The verified response is streamed back to the user interface via WebSockets.
- Simultaneously, the entire execution graph, tool payloads, latencies, and token costs are pushed asynchronously to the Langfuse Worker for observability and future analysis (integration in Sprint 11).

### API Specification — `POST /api/v1/ask`

| Field | Value (from PRD) |
|---|---|
| **Method** | POST |
| **Path** | `/api/v1/ask` |
| **Purpose** | Synchronous endpoint reserved for non-streaming agentic queries or backend system integrations where continuous streaming is unnecessary. |

**Request Payload (from PRD):**

- The user's natural language string.
- A unique session identifier for LangGraph state tracking.
- Explicitly scoped document IDs to constrain the vector search.

**Response Payload (from PRD):**

- The synthesized answer.
- A structured array of citations mapping to specific `doc_id` and page numbers.
- A sequential list of the agent's internal steps.
- A direct URL to the resulting Langfuse observability trace.

### API Specification — `WS /api/v1/stream`

| Field | Value (from PRD) |
|---|---|
| **Method** | WS (WebSocket) |
| **Path** | `/api/v1/stream` |
| **Purpose** | Provides real-time user interface updates for long-running LangGraph agent workflows. Prevents client timeouts. |

**Behavior (from PRD):**

- Emits continuous status events (e.g., `{"type": "status", "message": "Querying Qdrant for financial data..."}`).
- Once the agent completes its ReAct loop, the WebSocket streams the raw token output of the final synthesis directly to the browser.

### NFR — Latency

- The system must stream the first token (Time-To-First-Token, TTFT) to the client within 2.5 seconds.
- For explicitly simple queries, the LangGraph architecture must utilize conditional edges to bypass the reasoning loop entirely, acting as a fast-path generator to minimize delay.

---

## Deliverables

1. Complete ReAct loop via LangGraph with iterative retrieval reformulation.
2. Qdrant hybrid search tool execution with ACL metadata filtering and top-K retrieval.
3. Citation synthesis mapping claims to `doc_id` and page numbers.
4. NeMo Guardrails input rejection and AlignScore output validation with forced regeneration.
5. `POST /api/v1/ask` endpoint with full request and response payload specification.
6. `WS /api/v1/stream` endpoint with status events and final token streaming.
7. Conditional edges fast-path bypassing reasoning loop for simple queries.
8. TTFT streaming within 2.5 seconds.

---

## Acceptance Criteria

- [ ] Natural language questions submitted to `/api/v1/ask` are routed through NeMo Guardrails; jailbreak and topical violations are instantly rejected.
- [ ] LangGraph RAG agent retrieves Mem0 conversation history and formulates a multi-step retrieval plan.
- [ ] Agent executes Qdrant hybrid search with RRF, returning top-K chunks matching user ACL metadata.
- [ ] Agent observes chunks and reformulates search terms when context is insufficient, contradictory, or empty.
- [ ] Agent refuses to push poor context to the generation step.
- [ ] Final response includes explicit citations mapping to `doc_id` and page numbers.
- [ ] NeMo Guardrails output rails block ungrounded hallucinations and force agent regeneration.
- [ ] `POST /api/v1/ask` returns synthesized answer, citations array, agent internal steps, and Langfuse trace URL.
- [ ] `WS /api/v1/stream` emits status events during execution and streams final synthesis tokens.
- [ ] TTFT is delivered to the client within 2.5 seconds.
- [ ] Conditional edges bypass the reasoning loop for explicitly simple queries.

---

## Out of Scope (addressed in later sprints)

- Langfuse trace storage and dashboard (Sprint 11)
- DeepEval accuracy measurement (Sprint 12)
- Prometheus infrastructure metrics (Sprint 12)
