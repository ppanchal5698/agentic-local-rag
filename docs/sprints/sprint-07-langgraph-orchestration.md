# Sprint 07 — LangGraph Agent Orchestration & State Persistence

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layer 1), Docker Compose (`api-gateway` LangGraph runtime), FR-3

**Depends on:** Sprint 01, Sprint 02, Sprint 03

**Primary persona:** AI Developer

---

## Objective

Deploy LangGraph as the production agent orchestration framework with durable PostgreSQL-backed state persistence, enabling cyclic ReAct reasoning loops.

---

## Scope

### LangGraph Framework (from PRD)

- Central nervous system of the RAG pipeline.
- Industry standard for production agent orchestration in 2026.
- Models multi-agent workflows as explicit state machines using Directed Acyclic Graphs (DAGs).
- Provides deterministic execution, auditable state transitions, and first-class support for Human-in-the-Loop (HITL) approvals.
- Cyclic reasoning loops where the output of a retrieval action dictates the next thought process.
- ReAct (Reasoning and Action) loop execution.
- Executes within the FastAPI Docker container (`api-gateway`), scaling horizontally while session states are centrally managed.

### State Persistence (from PRD)

- State persistence is critical to surviving spot instance evictions or container restarts.
- LangGraph achieves this using the PostgresSaver checkpointer, which writes a full state snapshot to a relational database after every completed node execution.
- AsyncPostgresSaver class writes every intermediate agent state, tool call, and scratchpad memory to disk.
- Allows workflows to pause for human approval and resume flawlessly.
- Workflows survive spot instance evictions or server crashes.

### LangGraph Framework Comparison (from PRD)

| Property | LangGraph |
|---|---|
| Mental Model | Explicit State Machine (DAG) |
| Best Production Use Case | Mission-critical workflows, highly regulated industries, auditable paths. |
| State Management Capability | Excellent. Native PostgreSQL checkpointing, time-travel debugging. |
| License | MIT |

### FR-3 — Stateful Agents

| Field | Value (from PRD) |
|---|---|
| **Feature Category** | Stateful Agents |
| **Detailed Requirement** | Agents must durably remember conversation context and support pausing for workflow resumption. |
| **Acceptance Criteria** | The LangGraph PostgresSaver accurately stores and retrieves specific `thread_id` states across simulated server restarts. |

---

## Deliverables

1. LangGraph agent orchestration runtime within the `api-gateway` FastAPI container.
2. PostgresSaver / AsyncPostgresSaver checkpointer writing state snapshots to PostgreSQL after every completed node execution.
3. Explicit state machine (DAG) modeling with cyclic reasoning loop support.
4. HITL pause and resume capability.
5. `thread_id`-based state tracking and retrieval.

---

## Acceptance Criteria

- [ ] LangGraph executes within the `api-gateway` FastAPI Docker container.
- [ ] Multi-agent workflows are modeled as explicit state machines (DAGs) with deterministic execution.
- [ ] PostgresSaver writes a full state snapshot to PostgreSQL after every completed node execution.
- [ ] Workflows can pause for human approval and resume flawlessly.
- [ ] **FR-3:** The LangGraph PostgresSaver accurately stores and retrieves specific `thread_id` states across simulated server restarts.
- [ ] Cyclic ReAct reasoning loops are supported.

---

## Out of Scope (addressed in later sprints)

- Mem0 conversation history retrieval (Sprint 08)
- Qdrant tool execution within agent loop (Sprint 10)
- NeMo Guardrails input/output interception (Sprint 09)
- Langfuse trace generation (Sprint 11)
- `POST /api/v1/ask` and `WS /api/v1/stream` endpoints (Sprint 10)
- Conditional edges fast-path for simple queries (Sprint 10)
