# Sprint 08 — Valkey Short-Term Caching & Mem0 Long-Term Memory

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layer 11)

**Depends on:** Sprint 01, Sprint 07

**Primary persona:** AI Developer

---

## Objective

Implement stratified agent memory across short-term Valkey storage and long-term Mem0 semantic memory to manage context window limitations and control token expenditures.

---

## Scope

### Valkey — Short-Term Memory (from PRD)

- Industry successor to Redis, backed by the Linux Foundation as an open-source, high-performance key-value datastore.
- Manages in-session memory.
- Retains scratchpad state.
- Fast tool call lookups.
- Duplicate request caching.
- Ephemeral application state (deployed in Sprint 01 on port `6379`).

### Mem0 — Long-Term Memory (from PRD)

- Manages persistent user knowledge across diverse sessions.
- Generates rolling summaries of prior interactions.
- Summarized knowledge stored as temporal knowledge graphs.
- Ensures agents maintain context over extended timelines without overflowing the LLM's strict context window limitations.
- PRD also references Zep as an alternative platform for long-term semantic memory.

### Integration Point (from PRD Section 3.2 — Strategic Planning)

- The primary LangGraph RAG agent accesses Mem0 to retrieve relevant short-term and long-term conversation history during the Strategic Planning step of the online query workflow.

---

## Deliverables

1. Valkey-backed in-session memory, scratchpad state, fast tool call lookups, and duplicate request caching.
2. Mem0 (or Zep) long-term semantic memory with rolling summaries stored as temporal knowledge graphs.
3. LangGraph agent integration to retrieve short-term and long-term conversation history from Mem0 during Strategic Planning.

---

## Acceptance Criteria

- [ ] Valkey manages in-session memory, scratchpad state, fast tool call lookups, and duplicate request caching.
- [ ] Mem0 (or Zep) stores persistent user knowledge as rolling summaries in temporal knowledge graphs across sessions.
- [ ] LangGraph RAG agent retrieves relevant short-term and long-term conversation history from Mem0 during Strategic Planning.

---

## Out of Scope (addressed in later sprints)

- Valkey as RQ message broker for Docling (Sprint 05, deployed in Sprint 01)
- Full online query workflow execution (Sprint 10)
- Langfuse memory of conversation traces (Sprint 11)
