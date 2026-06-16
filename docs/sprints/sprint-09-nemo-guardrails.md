# Sprint 09 — NeMo Guardrails

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layer 12), Docker Compose Network Topology Blueprint (`guardrails`), FR-6

**Depends on:** Sprint 01, Sprint 02

**Primary persona:** AI Developer

---

## Objective

Deploy NVIDIA NeMo Guardrails as an independent validation proxy enforcing programmatic safety boundaries, topic restriction, format enforcement, and hallucination detection.

---

## Scope

### `guardrails` Service

| Property | Value (from PRD) |
|---|---|
| Docker Image | `nemoguardrails:latest` |
| Port Mapping | `8010:8000` |
| Volume / State | `config/` directory mount |

**Core responsibilities (from PRD):**

- Input/Output policy verification.
- Colang enforcement.
- AlignScore fact-checking.
- Operates as an independent validation proxy intercepting traffic between the FastAPI gateway and the LangGraph orchestration layer.

### Input Rails (from PRD)

- Actively scan incoming prompts to detect and neutralize complex jailbreak attempts before they trigger the orchestration graph.
- If the input contains a recognized jailbreak heuristic or violates topical boundaries, the request is instantly rejected.

### Output Rails (from PRD)

- Prevent Personally Identifiable Information (PII) leakage.
- Enforce specific communication tones.
- AlignScore model cross-references the generated text against the originally retrieved chunks.
- If ungrounded hallucination is detected, the output is blocked and the agent is forced to regenerate.

### Colang Policies (from PRD)

- Engineers define rigid operational policies using Colang, a specialized specification language.

### Integration Points (from PRD Section 3.2)

1. **Request Reception and Security:** The prompt is immediately routed through NeMo Guardrails. Jailbreak or topical boundary violations result in instant rejection.
2. **Fact-Checking:** The generated synthesis is intercepted by NeMo Guardrails' output rails. AlignScore validates the response against retrieved chunks. Ungrounded hallucinations block output and force agent regeneration.

### FR-6 — Programmatic Guardrails

| Field | Value (from PRD) |
|---|---|
| **Feature Category** | Programmatic Guardrails |
| **Detailed Requirement** | The system must strictly prevent policy violations and generative hallucinations. |
| **Acceptance Criteria** | NeMo Guardrails successfully blocks test inputs matching defined Colang jailbreak patterns and utilizes AlignScore to flag fabricated responses. |

---

## Deliverables

1. `guardrails` container deployed as `nemoguardrails:latest` on port `8010:8000` with `config/` directory mount.
2. Input rails detecting and neutralizing jailbreak attempts and topical boundary violations.
3. Output rails preventing PII leakage and enforcing communication tones.
4. AlignScore fact-checking cross-referencing generated text against retrieved chunks.
5. Colang policy definitions for operational boundaries.
6. Traffic interception between FastAPI gateway and LangGraph orchestration layer.

---

## Acceptance Criteria

- [ ] `guardrails` is deployed as `nemoguardrails:latest` on port `8010:8000` with `config/` directory mount.
- [ ] Input rails scan incoming prompts and instantly reject jailbreak heuristics and topical boundary violations.
- [ ] Output rails prevent PII leakage and enforce communication tones.
- [ ] AlignScore cross-references generated synthesis against originally retrieved chunks.
- [ ] Ungrounded hallucination blocks output and forces agent regeneration.
- [ ] **FR-6:** NeMo Guardrails successfully blocks test inputs matching defined Colang jailbreak patterns and utilizes AlignScore to flag fabricated responses.
- [ ] Service intercepts traffic between FastAPI gateway and LangGraph orchestration layer.

---

## Out of Scope (addressed in later sprints)

- Full online query workflow wiring (Sprint 10)
- DeepEval Faithfulness metric validation (Sprint 12)
