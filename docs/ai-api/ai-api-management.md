# Stack BOM — AI Workloads & API Management (Appendix D)

**Date:** 2026-03-05
**Scope:** Local inference, production ML serving, training/fine-tuning on HPC/GPU, API management (east-west governance, north-south exposure, LLM gateway)
**Status:** DRAFT — covers architecture + BOM additions

---

## Part 1: AI Workload Architecture

### 1.1 — Three workload tiers

```
┌───────────────────────────────────────────────────────────────────┐
│                        AI WORKLOAD TIERS                          │
│                                                                   │
│  Tier A: Local inference (lab/dev)                                │
│    Ollama + Open WebUI + Qdrant                                   │
│    Single node (axiom); no SLO; rapid iteration                   │
│                                                                   │
│  Tier B: Production inference (cluster/prod)                      │
│    vLLM/TGI behind API gateway                                    │
│    Multi-tenant; SLO-bound; canary/rollback                       │
│    RAG pipeline with Qdrant + embedding version pinning           │
│    OTel GenAI instrumentation; safety filters; kill-switch        │
│                                                                   │
│  Tier C: Training / fine-tuning (HPC/GPU)                         │
│    Slurm + NVIDIA CUDA/NCCL + Apptainer                          │
│    MLflow experiment tracking + model registry                    │
│    Dataset versioning (DVC or hash-pinned manifests)              │
│    Checkpoint integrity (ZFS + GPU ECC + DCGM health)             │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### 1.2 — Tier A: Local inference (already in BOM)

No BOM changes needed. Ollama + Open WebUI + Qdrant on `axiom`. T3 convenience dependency. No governance overhead beyond keeping model weights hash-pinned.

### 1.3 — Tier B: Production inference

This is where the new controls matter. A production LLM/ML serving stack introduces five trust boundaries not present in traditional services:

```
User/client
  │
  ▼
┌─────────────────────┐
│ API Gateway          │  ← TB1: AuthN, rate limiting, input validation
│ (Kong/Envoy)         │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ LLM Gateway          │  ← TB2: Prompt filtering, token budget, safety filters
│ (custom / LiteLLM)   │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Inference server     │  ← TB3: Model boundary (PIAL enforcement)
│ (vLLM / TGI)         │      Input contract, output contract, latency budget
└────────┬────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌─────────┐
│ Qdrant │ │ Tool    │  ← TB4: Retrieval boundary (RAG); Tool execution boundary
│ (RAG)  │ │ sandbox │      Access control on corpus; sandboxed execution
└────────┘ └─────────┘
```

**PIAL — Prompt Interface Assurance Layer:** The set of enforceable contracts at TB3 (the model serving boundary) that govern interactions between the LLM gateway and the inference server. A PIAL specifies: (1) the *input contract* — schema, token budget ceiling, and content constraints on prompts sent to the model; (2) the *output contract* — schema, maximum token length, content policy requirements, and structured-output validation rules applied to completions before they are returned upstream; and (3) the *latency budget* — per-request and p99 response-time thresholds used to trigger circuit-breaking or fallback routing. Together these contracts make the model boundary auditable and substitutable: any inference backend (vLLM, TGI, or third-party) that satisfies the PIAL can be swapped in without renegotiating upstream gateway policy. [I] {80}

### 1.4 — Tier C: Training / fine-tuning

Trust boundaries for training:

```
Data pipeline
  │
  ▼
┌─────────────────────┐
│ Dataset registry     │  ← TB5: Data provenance + quality gates
│ (DVC / hash manifests)│     Consent metadata, bias checks, lineage
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Training infra       │  ← TB6: GPU integrity (ECC, XID, thermal)
│ (Slurm + CUDA/NCCL) │     Checkpoint integrity (ZFS)
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ MLflow registry      │  ← TB7: Model promotion gate
│ (experiment + model) │     Quality gate, approval, signing
└────────┬────────────┘
         │
         ▼
        Tier B (production inference)
```

---

## Part 2: API Management Architecture

### 2.1 — Three API management layers

| Layer | Scope | Primary controls | Tool |
|-------|-------|-----------------|------|
| **North-south** (external) | Internet-facing APIs; consumer/partner access | AuthN/AuthZ, rate limiting, TLS termination, request validation, WAF, DDoS, API versioning | Kong or Envoy Gateway |
| **East-west** (internal) | Service-to-service within cluster | mTLS, RBAC, circuit breaking, retry policy, observability | Cilium + Istio/Linkerd (or Envoy sidecar) |
| **LLM gateway** (AI-specific) | LLM inference routing, prompt policy, token budgets, model multiplexing | Input/output filtering, token rate limiting, cost circuit breaker, model routing, prompt versioning | LiteLLM / custom proxy / Kong AI Gateway plugin |

### 2.2 — North-south API gateway

```
Internet
  │
  ▼
┌──────────────────────────────────────────┐
│  Kong / Envoy Gateway                     │
│                                           │
│  Plugins / filters:                       │
│  ├── OIDC auth (Keycloak)                │
│  ├── Rate limiting (per consumer key)     │
│  ├── Request size limit                   │
│  ├── Request validation (OpenAPI schema) │
│  ├── IP allow/deny                       │
│  ├── WAF (Coraza plugin)                 │
│  ├── Request/response logging → OTel     │
│  ├── API key management                  │
│  └── CORS policy                         │
│                                           │
│  Observability:                           │
│  ├── Prometheus metrics (latency, errors,│
│  │   rate, saturation per route)         │
│  ├── OTel traces (request → upstream)    │
│  └── Access logs → OpenSearch            │
│                                           │
└──────────────────────────────────────────┘
```

### 2.3 — East-west service mesh

Already partially in BOM (Cilium + Istio/Linkerd conditional). The API management addition is explicit governance of service-to-service communication:

- **mTLS everywhere** (Cilium mutual auth or Istio/Linkerd)
- **AuthZ policies** — which service can call which service (Cilium NetworkPolicy + L7 policy, or Istio AuthorizationPolicy)
- **Circuit breaking** — prevent cascade failures (Envoy circuit breaker via Istio DestinationRule)
- **Retry budgets** — bounded retries to prevent amplification
- **Observability** — per-service golden signals (latency, error rate, traffic, saturation) via OTel + Prometheus

### 2.4 — LLM gateway (new component)

This is the critical missing piece. An LLM gateway sits between the API gateway and the inference server, enforcing AI-specific policies that a generic API gateway cannot handle.

```
API Gateway (Kong/Envoy)
  │
  ▼
┌──────────────────────────────────────────┐
│  LLM Gateway                              │
│                                           │
│  Input controls:                          │
│  ├── Token count enforcement (reject if  │
│  │   input > budget)                     │
│  ├── Prompt injection detection (regex + │
│  │   classifier-based)                   │
│  ├── PII detection + redaction (before   │
│  │   sending to model)                   │
│  ├── Content policy filter (block        │
│  │   prohibited categories)              │
│  └── System prompt injection (attach     │
│      versioned system prompt per route)  │
│                                           │
│  Routing:                                 │
│  ├── Model selection per route/consumer  │
│  ├── Fallback chain (primary → secondary │
│  │   model on failure)                   │
│  ├── A/B split for model comparison      │
│  └── Shadow mode for new models          │
│                                           │
│  Output controls:                         │
│  ├── Output token limit enforcement      │
│  ├── PII/secret pattern detection +      │
│  │   redaction (before returning to user)│
│  ├── Content safety filter               │
│  ├── Citation/grounding check (RAG)      │
│  └── Structured output validation        │
│      (JSON schema if expected)           │
│                                           │
│  Cost / resource controls:                │
│  ├── Per-user/org token budget (daily/   │
│  │   monthly ceiling)                    │
│  ├── Cost circuit breaker (halt if daily │
│  │   spend > threshold)                  │
│  ├── Queue depth limit                   │
│  └── Concurrent request limit per user   │
│                                           │
│  Observability (OTel GenAI conventions):  │
│  ├── gen_ai.usage.input_tokens           │
│  ├── gen_ai.usage.output_tokens          │
│  ├── gen_ai.client.operation.duration    │
│  ├── gen_ai.response.finish_reasons      │
│  ├── Prompt/response logging (redacted)  │
│  └── Safety filter trigger rate          │
│                                           │
│  Kill-switch:                             │
│  ├── Feature flag to disable model       │
│  │   serving instantly                   │
│  ├── Degraded mode: return cached/static │
│  │   response instead of live inference  │
│  └── Manual and automated triggers       │
│                                           │
└──────────────────────────────────────────┘
```

**Tool options for LLM gateway:**

| Option | License | Fit | Trade-off |
|--------|---------|-----|-----------|
| LiteLLM Proxy | MIT | Good — model routing, token tracking, rate limiting, OpenAI-compatible API | Less mature on safety filtering; custom filters needed |
| Kong AI Gateway plugin | Apache 2.0 (Kong OSS) | Good — if Kong is already the API gateway; native AI plugin ecosystem | Kong Enterprise features may be needed for advanced AI policies |
| Custom proxy (Python/Go) | Your own | Maximum control; exactly your PIAL contracts | Build + maintain cost |
| MLflow AI Gateway | Apache 2.0 | Lightweight; model routing + rate limiting | Limited safety filtering |

**Recommendation:** Kong as the north-south API gateway + LiteLLM as the LLM-specific gateway behind it. This separates concerns cleanly — Kong handles generic API management (auth, rate limiting, WAF), LiteLLM handles AI-specific routing and policy. Both are OSS. [I] {80}

---

## Part 3: BOM Additions

### §15 — API management

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Kong (OSS) | External API admission (north-south) | T1 | C,P | Envoy Gateway acceptable; must support OIDC, rate limiting, request validation, plugin architecture. Kong Enterprise for advanced analytics. | Access logs, rate limit decisions, API call metrics |
| Coraza WAF (Kong plugin) | L7 threat filtering | T1 | P | ModSecurity acceptable; must integrate with API gateway | WAF block/allow decisions |
| Cilium + mTLS | Service-to-service auth (east-west) | T0* | C,P | Istio/Linkerd if full mesh needed; Cilium mutual auth for lightweight mTLS | mTLS handshake logs, policy decisions |
| LiteLLM Proxy | LLM routing + token budget + rate limiting | T1 | C,P | Custom proxy acceptable; must support model routing, token tracking, OpenAI-compatible API | Token usage per user/model, routing decisions |
| LLM safety filter (custom) | Input/output policy enforcement | T0 | P | No off-the-shelf OSS fully covers this; custom filters on LiteLLM proxy or standalone | Filter decisions (block/redact/pass), trigger rates |

### §16 — AI workload governance (production serving)

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| vLLM | Production LLM inference | T1 | P | TGI acceptable; must support continuous batching, quantization, OpenAI-compatible API | Inference latency/error/token metrics |
| TGI | Production LLM inference (alt) | T1 | P | vLLM acceptable; choose per model compatibility | Same as vLLM |
| OTel GenAI instrumentation | Inference observability | T0 | P | Non-negotiable — GenAI semantic conventions for every inference call | Traces with token counts, latency, finish reason |
| Prompt version control | Prompt/system prompt lineage | T1 | C,P | Git-based (prompt templates in repo) or LiteLLM config; must be versioned and auditable | Prompt version history in VCS |
| Eval harness (golden sets) | Output quality gate | T0 | L,P | lm-eval-harness + custom golden sets; must include regression, jailbreak, bias suites | Eval reports per model version |
| Red team / adversarial suite | Security validation | T0 | L,P | Custom + community jailbreak suites; OWASP LLM Top 10 coverage | Red team report, ATLAS coverage matrix |
| Kill-switch | Actuation boundary (emergency halt) | T0 | P | Feature flag (LaunchDarkly OSS / Flipt / Unleash) or Argo Rollouts instant rollback | Kill-switch activation log |
| Model BOM (MBOM) | Model provenance | T0 | P | CycloneDX MLBOM emerging; structured manifest | Signed model manifest |
| Dataset BOM (DBOM) | Data provenance | T0 | P | Structured manifest with consent/retention metadata | Signed dataset manifest |

### §17 — AI workload governance (training / fine-tuning)

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| MLflow (tracking + registry) | Experiment lineage + model promotion gate | T1 | L | W&B acceptable; must support immutable run logging, model staging gates, API access control | Experiment logs, registry audit trail |
| Model signing (cosign) | Model artifact integrity | T0 | L,P | Same signing pipeline as container images; model weights signed before registry promotion | Signed model digest + Rekor entry |
| DVC / hash manifests | Dataset versioning | T2 | L | Git-native hash manifests acceptable if datasets are small; DVC for large datasets | Dataset version hashes in VCS |
| Quality gate (automated) | Promotion boundary | T0 | L,P | Custom script; must check metrics, fairness, reproducibility, SBOM scan before promotion | Gate pass/fail log per model version |
| Reproducibility check | Training integrity verification | T1 | L | Re-run subset with same inputs; verify metric delta within tolerance | Reproducibility report |
| DCGM / NVML health monitoring | GPU integrity during training | T0 | L | ROCm equivalents for AMD; must detect ECC errors, XID events, thermal violations | GPU health log, ECC error counts |
| Checkpoint integrity (ZFS) | Training state integrity | T0 | L | ZFS checksumming on checkpoint storage; scrub after long training runs | ZFS scrub reports, checkpoint hashes |

---

## Part 4: Security controls for AI workloads (OWASP LLM Top 10 mapped)

| OWASP LLM # | Threat | Control | Stack component |
|-------------|--------|---------|-----------------|
| LLM01 | Prompt injection | Input validation + privilege separation + output validation before tool execution | LLM gateway safety filter; tool sandbox |
| LLM02 | Sensitive info disclosure | No secrets in system prompts; output PII filter; session isolation | LLM gateway output filter; Keycloak session isolation |
| LLM03 | Supply chain | Model provenance; weight hash verification; dependency scanning | cosign model signing; Trivy; MBOM |
| LLM04 | Data/model poisoning | Dataset provenance; training data quality gates; RAG corpus access control | DBOM; MLflow lineage; Qdrant access control |
| LLM05 | Insecure output handling | Treat LLM output as untrusted; parameterise queries; sandbox code | Tool sandbox; output validation |
| LLM06 | Excessive agency | Least-privilege tool grants; human-in-loop for irreversible actions; action rate limit | LLM gateway tool policy; kill-switch |
| LLM07 | System prompt confidentiality | Treat as confidential but not security boundary; log hash not content | Prompt version control; OTel prompt.id attribute |
| LLM08 | Vector/embedding weaknesses | RAG access control independent of similarity; retrieval rate limiting | Qdrant access control; LLM gateway |
| LLM09 | Misinformation | RAG with source citation; eval harness; human review for high-stakes | Eval harness; content grounding check |
| LLM10 | Unbounded consumption | Token budget per user/session; cost circuit breaker; queue depth limit | LiteLLM token tracking; LLM gateway rate limiting |

---

## Part 5: Evidence requirements specific to AI workloads

These feed into the evidence pipeline (Appendix C) via the same generate → sign → store flow.

| Evidence artifact | Source | Framework requirement | Storage tier |
|-------------------|--------|----------------------|--------------|
| Model BOM (signed) | CI/release pipeline | CRA Annex I (if product); AI Act technical documentation | ci_3y (10y if manufacturer) |
| Dataset BOM (signed) | Data pipeline | AI Act Art 10 (data governance); GDPR Art 30 (ROPA linkage) | governance_10y |
| Experiment tracking log | MLflow | AI Act Art 12 (automatic logging); ISO 42001 | ci_3y |
| Model registry audit trail | MLflow | AI Act Art 12; NIS2 Art 21 (change management) | ci_3y |
| Quality gate results (per model) | CI/promotion pipeline | AI Act Art 9 (risk management); CRA Annex I | ci_3y |
| Red team report | Security team | AI Act Art 9; OWASP LLM assessment | governance_10y |
| Eval harness results (per release) | CI/eval pipeline | AI Act Art 9; post-market monitoring | ci_3y |
| OTel GenAI traces (production) | OTel Collector | AI Act Art 12 (logging); NIS2 Art 21 (monitoring) | runtime_1y |
| Token usage / cost records | LiteLLM / LLM gateway | AI Act Art 12; internal cost governance | runtime_1y |
| Safety filter decisions | LLM gateway | AI Act Art 14 (human oversight); NIS2 Art 21 | runtime_1y |
| Kill-switch activation log | Feature flag / Argo | AI Act Art 14; CRA Annex I (incident response) | incident_5y |
| Prompt version history | Git | AI Act technical documentation | governance_10y |
| DPIA for AI processing | DPO | GDPR Art 35 (mandatory for AI profiling) | governance_10y |
| Fairness/bias evaluation | Eval pipeline | AI Act Art 10; ISO 42001 | ci_3y |
| GPU health reports (training) | DCGM / NVML | Internal (training integrity) | runtime_1y |

---

## Part 6: Implementation roadmap

| Phase | Scope | Dependencies | Effort |
|-------|-------|-------------|--------|
| **P1** | Kong API gateway (north-south): deploy, configure OIDC + rate limiting + Coraza WAF | Keycloak already in stack | M |
| **P2** | East-west mTLS: Cilium mutual auth OR Istio/Linkerd; default-deny NetworkPolicy | Cilium already in stack | M |
| **P3** | LiteLLM proxy: deploy behind Kong; configure model routing + token budgets | Kong from P1; vLLM/TGI already in stack | S–M |
| **P4** | LLM safety filters: input/output validation, PII detection, prompt injection detection | LiteLLM from P3 | M |
| **P5** | OTel GenAI instrumentation: instrument inference path; connect to existing OTel Collector | OTel already in stack | S |
| **P6** | MLflow governance: configure immutable experiment tracking, model registry with promotion gates, cosign signing | MLflow + cosign already in stack | M |
| **P7** | Eval harness: golden set regression + jailbreak suite + bias checks; integrate into CI | GitLab CI already in stack | M |
| **P8** | Model + Dataset BOM generation: structured manifests, signed, uploaded to evidence store | Evidence pipeline (Appendix C) | S |
| **P9** | Kill-switch: feature flag for instant model disable + degraded mode fallback | Flipt/Unleash (new, small) or Argo Rollouts | S |
| **P10** | Red team engagement: scope, execute, report; feed findings into security controls | P4 complete (safety filters to test) | M |

**Total:** ~3–4 months for a single engineer, phased. P1–P5 deliver the API + inference serving layer. P6–P10 deliver training governance and security validation.

---

## Part 7: New dependencies summary

| Component | License | Category | Purpose | Already in BOM? |
|-----------|---------|----------|---------|-----------------|
| Kong (OSS) | Apache 2.0 | OSS | API gateway | No — **new** |
| LiteLLM Proxy | MIT | OSS | LLM gateway | No — **new** |
| Flipt or Unleash | GPL 3.0 / Apache 2.0 | OSS | Feature flags (kill-switch) | No — **new** (or use Argo Rollouts instant rollback) |
| Coraza WAF | Apache 2.0 | OSS | WAF plugin for Kong | No — **new** (also identified in Appendix C security assessment) |
| Gitleaks | MIT | OSS | Secret scanning in CI | No — **new** (also identified in Appendix C) |

All new dependencies are OSS with permissive licenses. No proprietary additions. [F]

---

*All architecture claims [I,80]. Tool-specific API details [S,75] — verify against current upstream documentation. OWASP LLM Top 10 references [S,80] — verify against 2025 edition. OTel GenAI semantic conventions [S,75] — some attributes experimental.*
