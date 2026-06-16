# Sprint 03 — LiteLLM Gateway & vLLM Inference

**Source of truth:** `docs/PRD.md`

**PRD references:** 12-Layer Golden Tech Stack (Layer 2), Docker Compose Network Topology Blueprint (`litellm-proxy`, `vllm-inference`), FR-4

**Depends on:** Sprint 01

**Primary persona:** System Administrator, AI Developer

---

## Objective

Deploy the two-tier LLM backend that decouples orchestration from physical inference hardware, providing high availability, cost control, and provider flexibility.

---

## Scope

### LiteLLM Gateway (`litellm-proxy`)

| Property | Value (from PRD) |
|---|---|
| Docker Image | `litellm:main-stable` |
| Port Mapping | `4000:4000` |
| Volume / State | `config.yaml` bind mount |

**Responsibilities (from PRD):**

- Universal AI gateway providing a unified, OpenAI-compatible endpoint.
- Standardize request schemas across hundreds of commercial and open-source model providers.
- Load balancing, virtual key management, and rigorous cost tracking per user or project.
- Read routing logic from a bound `config.yaml` file.
- Store API keys safely via environment variables, ensuring credentials never leak into container images.
- Route complex reasoning tasks to frontier cloud models like Claude 4.
- Route high-volume, privacy-sensitive extraction tasks to local vLLM instances.
- Track virtual API keys, spend limits, and execute programmatic access controls across the user base (PostgreSQL backend from Sprint 01).

### vLLM Inference (`vllm-inference`)

| Property | Value (from PRD) |
|---|---|
| Docker Image | `vllm/vllm-openai:latest` |
| Port Mapping | `8001:8000` |
| Volume / State | Hugging Face model cache |
| Hardware | Requires GPU passthrough |

**Responsibilities (from PRD):**

- Hardware-accelerated execution of local models (e.g., Llama 4).
- Utilize TensorRT-LLM compiled kernels and PagedAttention mechanisms to maximize GPU throughput.
- Handle massive context windows required by Agentic RAG document synthesis.

### FR-4 — Routing and Fallbacks

| Field | Value (from PRD) |
|---|---|
| **Feature Category** | Routing and Fallbacks |
| **Detailed Requirement** | The system must maintain high availability for LLM requests despite localized failures. |
| **Acceptance Criteria** | LiteLLM automatically routes requests to a secondary provider model if the primary vLLM instance exceeds a defined timeout threshold. |

---

## Deliverables

1. `litellm-proxy` container on port `4000` with `config.yaml` bind mount and environment-variable API keys.
2. `vllm-inference` container on port `8001:8000` with GPU passthrough and Hugging Face model cache volume.
3. Unified OpenAI-compatible endpoint routing to vLLM and external API providers.
4. Virtual key management and cost tracking backed by PostgreSQL.
5. Automatic fallback routing to a secondary provider model on primary vLLM timeout.

---

## Acceptance Criteria

- [ ] `litellm-proxy` is deployed as `litellm:main-stable` on port `4000:4000` with `config.yaml` bind mount.
- [ ] `vllm-inference` is deployed as `vllm/vllm-openai:latest` on port `8001:8000` with GPU passthrough and model cache volume.
- [ ] LiteLLM provides a unified, OpenAI-compatible endpoint with load balancing and cost tracking.
- [ ] API keys are stored via environment variables and do not leak into container images.
- [ ] **FR-4:** LiteLLM automatically routes requests to a secondary provider model if the primary vLLM instance exceeds a defined timeout threshold.

---

## Out of Scope (addressed in later sprints)

- LangGraph agent LLM invocation (Sprint 07)
- Prometheus `/metrics` scraping for vLLM and LiteLLM (Sprint 12)
- Langfuse token cost tracing (Sprint 11)
