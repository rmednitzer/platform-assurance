# Stack BOM — Tiered Platform Architecture

**Author:** Roman Mednitzer
**Date:** 2026-03-05
**Status:** DRAFT — review tiers and substitution constraints before procurement
**Scope:** Operator workstation + lab + cluster + regulated production

---

## Document set

The BOM is a rendered architecture view. The canonical control source is `controls/catalog.yaml`. Generated derivatives live under `docs/generated/`.

| # | Document | File | Content |
|---|----------|------|---------|
| — | **Stack BOM** | `docs/architecture/stack-bom.md` | Tiered component inventory (§1–§17) |
| G | Canonical control catalog | `controls/catalog.yaml` | Stable IDs, applicability predicates, evidence schema |
| H | Generated control catalog | `docs/generated/control-catalog.md` | Rendered control view |
| I | Generated applicability matrix | `docs/generated/applicability-matrix.md` | Date- and role-gated applicability |
| J | Automated consistency report | `docs/generated/consistency-report.md` | Generated validation output |
| A | License Audit | `docs/compliance/license-audit.md` | OSS/BSL/proprietary per component |
| B | Regulatory Mapping | `docs/compliance/regulatory-mapping.md` | NIS2/CRA/GDPR → stack controls + gap analysis |
| C | Evidence Pipeline | `docs/evidence/evidence-pipeline.md` | Evidence generation, signing, storage (MinIO WORM + OpenSearch catalogue) |
| D | AI & API Management | `docs/ai-api/ai-api-management.md` | AI workload tiers + API gateway + LLM gateway + OWASP LLM |
| E | Observability + IAM | `docs/observability/observability-iam.md` | Request-to-evidence flow + IAM architecture |
| F | ISMS Policy Set | `docs/compliance/isms-policies.md` | 10 policies + supporting docs, cross-referenced to NIS2/CRA/GDPR/ISO 27001/SCF/Austrian law |
| K | Security Assessment | `docs/security/security-assessment.md` | STRIDE threat model per trust boundary + gap analysis |

---

## Tiering model

| Tier | Meaning | Failure impact | Change gate |
|------|---------|----------------|-------------|
| **T0 — Safety / integrity** | Violation = unsafe state, data loss, or unrecoverable compliance failure | Blocks production; may trigger incident/notification obligations | Full change plan + rollback + evidence |
| **T1 — Operational** | Required for daily ops, SRE, delivery; outage = degraded capability | Degrades velocity or observability; SLO impact | Standard change + verify + rollback |
| **T2 — Productivity** | Developer/operator quality-of-life; outage = inconvenience | Workaround available; no compliance impact | Lightweight change |
| **T3 — Exploratory / optional** | Future capability, evaluation, nice-to-have | No operational dependency | Self-service |

---

## Reading the table

- **Component**: tool, service, or capability
- **Boundary enforced**: which PIAL enforcement point this component serves (if any)
- **Tier**: T0–T3
- **Env**: W = workstation, L = lab, C = cluster, P = prod (regulated)
- **Substitution constraints**: what you can swap in and what you cannot
- **Evidence output**: what this component produces for audit/assurance

---

## 1 — Identity, secrets, and trust anchors

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Keycloak | Admission (AuthN/AuthZ) | T0 | C,P | Any OIDC IdP; must support MFA, RBAC/ABAC, audit log export | Auth decision logs, session audit trail |
| Vault / OpenBao | Secret boundary | T0 | C,P | Interchangeable (OpenBao is the LF fork of Vault post-BSL; API-compatible). Must support dynamic secrets, audit backend, lease revocation. Vault Enterprise needed for namespaces/replication/Sentinel — evaluate license posture. | Secret access audit log, lease records |
| SOPS + age | Secret-at-rest (GitOps) | T1 | C,P | age/GPG interchangeable; must integrate with Git workflow | Encrypted secret manifests in VCS |
| External Secrets Operator | Secret injection (K8s) | T1 | C,P | Secrets Store CSI as alternative; must not expose plaintext in etcd | Reconciliation logs |
| cert-manager | PKI / mTLS boundary | T0 | C,P | Manual cert rotation possible but audit burden explodes; no real substitute at scale | Cert issuance/renewal logs, expiry alerts |
| GPG/SSH signing (commits/tags) | Code provenance | T0 | W,L,C,P | SSH signing acceptable alternative to GPG; must be enforced by VCS server | Signed commit metadata |

## 2 — Supply chain integrity

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Syft | Inventory (SBOM generation) | T0 | C,P | CycloneDX CLI acceptable; must produce SPDX or CycloneDX JSON | SBOM artifacts (OCI-attached) |
| cosign (Sigstore) | Artifact signing / verification | T0 | C,P | Key-based GPG signing as fallback; Sigstore keyless preferred for transparency | Signature + Rekor transparency entry |
| Rekor | Signing transparency log | T1 | C,P | Self-hosted or public instance; required if using keyless | Tamper-evident log entries |
| in-toto / DSSE | Build provenance attestation | T0 | C,P | SLSA provenance generators (GitHub/GitLab native) acceptable | Signed attestation envelopes |
| Trivy | Vuln scanning (images, IaC, fs) | T0 | C,P | Grype interchangeable; must support OCI image + filesystem + IaC scanning | Vuln scan reports (JSON) |
| osv-scanner | Vuln scanning (OSV database) | T1 | C,P | Complementary to Trivy, not substitute; different vuln source | OSV match reports |
| CycloneDX VEX / CSAF VEX | Vuln triage documentation | T1 | C,P | Either format acceptable; must be machine-parsable | VEX documents per release |
| Kyverno | Admission enforcement (policy) | T0 | C,P | OPA/Gatekeeper interchangeable; must enforce sig + provenance + SBOM at admission | Policy decision audit logs |
| ORT / SCA tooling | License compliance | T1 | C,P | FOSSA/Snyk/Black Duck per org; must produce license inventory | License compliance reports |
| Renovate / Dependabot | Dependency update automation | T2 | C,P | Interchangeable; must create auditable PRs | Update PRs with changelogs |

## 3 — Platform core (Kubernetes / containers)

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Kubernetes / OpenShift | Orchestration platform | T0 | C,P | OpenShift adds operator lifecycle + compliance features; upstream K8s viable with discipline | API audit logs, event stream |
| containerd | Container runtime | T0 | C,P | CRI-O acceptable; Docker/Podman for build only | Runtime logs |
| Harbor / GitLab Registry | Image + OCI artifact store | T0 | C,P | Must support OCI artifacts (SBOM/attestation storage), vulnerability scanning, replication | Image pull audit, replication logs |
| Cilium | CNI + network policy enforcement | T0 | C,P | Calico acceptable; Cilium preferred for eBPF observability + L7 policy | Network policy audit, flow logs |
| cert-manager | See §1 | T0 | C,P | — | — |
| CoreDNS | Cluster DNS | T1 | C,P | No practical substitute in K8s | DNS query logs (if enabled) |
| MetalLB | Load balancer (bare metal) | T1 | C | Cloud LB in cloud; no substitute on bare metal | ARP/BGP logs |
| Helm / Kustomize | Manifest templating | T1 | C,P | Interchangeable; Kustomize for simple, Helm for complex/3rd-party | Rendered manifests in Git |
| Istio / Linkerd (mTLS) | Service-to-service authentication | T0* | P | *T0 if NIS2/DORA requires encrypted east-west; T2 otherwise. Cilium mTLS may substitute. | mTLS handshake logs, policy decisions |
| Ingress (NGINX/HAProxy/Traefik) | External admission | T1 | C,P | Interchangeable; Gateway API convergence underway | Access logs, TLS termination config |

## 4 — GitOps, IaC, config management

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| GitLab (VCS + CI) | Code provenance + build pipeline | T0 | W,L,C,P | GitHub Enterprise acceptable; must support protected branches, signed commits, compliance pipelines | Pipeline logs, merge audit trail |
| Argo CD / Flux | Desired-state enforcement (GitOps) | T0 | C,P | Interchangeable; must reconcile from Git with drift detection | Sync status, drift alerts, reconciliation logs |
| Terraform | Infrastructure provisioning | T1 | C,P | OpenTofu acceptable; Terragrunt optional layer | State files, plan outputs |
| Ansible | Config management / orchestration | T1 | L,C,P | Salt/Puppet possible but ecosystem mismatch; Ansible fits existing stack | Playbook run logs, facts |
| Packer | Image build | T2 | L,C | Direct container builds may substitute; Packer for VM images | Build manifests |

## 5 — Observability + forensics readiness

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Prometheus + Alertmanager | Metric collection + alerting | T0 | C,P | VictoriaMetrics as drop-in; must support recording/alerting rules, federation | Metric time-series, alert history |
| Thanos / VictoriaMetrics | Long-term metric storage | T1 | C,P | Interchangeable; must support multi-tenant, retention, downsampling | Retained historical metrics |
| Grafana | Dashboards + unified query | T1 | C,P | No practical substitute at this integration level | Dashboard definitions (IaC) |
| OpenTelemetry (SDK + Collector) | Trace / metric / log pipeline | T0 | C,P | Non-negotiable — vendor-neutral instrumentation standard | Traces, enriched logs, OTLP exports |
| Loki / Elasticsearch / OpenSearch | Log aggregation | T1 | C,P | Interchangeable with trade-offs (cost, query model); must support retention + access control | Indexed log streams |
| Fluent Bit / Vector | Log shipping | T1 | C,P | Interchangeable; Vector has better transform pipeline | Shipping pipeline metrics |
| Checkmk | Host/service monitoring | T1 | L,C,P | Zabbix acceptable; already in stack | Availability records, check history |
| auditd + journald | OS-level forensic trail | T0 | L,C,P | Non-negotiable for Linux forensics; auditd rules tuned to CIS | Audit logs (append-only where feasible) |
| chrony | Time sync | T0 | L,C,P | ntpd acceptable; time accuracy is evidence integrity dependency | NTP sync status logs |
| Wazuh | EDR / SIEM / FIM | T1 | C,P | OSSEC-based alternatives; must support FIM + Sigma rules + active response | Security event logs, FIM alerts |

## 6 — Security engineering (runtime)

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| SELinux / AppArmor | Process confinement | T0 | C,P | Either acceptable; must be in enforcing mode in prod | Policy violation logs |
| seccomp profiles | Syscall restriction | T0 | C,P | Must be applied to all production containers | Profile definitions in VCS |
| Falco / eBPF detection | Runtime anomaly detection | T1 | C,P | Tetragon (Cilium) as alternative; must detect unexpected syscalls/file access/network | Alert stream, event logs |
| OPA / Kyverno (CI) | Pre-deployment policy check | T0 | C,P | conftest for CI-time checks; Kyverno/Gatekeeper at admission (see §2) | Policy pass/fail per pipeline |
| Trivy (IaC scanning) | IaC misconfig detection | T1 | C,P | Checkov/tfsec acceptable | IaC scan reports |
| Gitleaks | Secret scanning (CI + pre-commit) | T1 | C,P | truffleHog acceptable; must run pre-merge | Secret detection alerts, scan pass/fail per pipeline |

## 7 — Storage, backup, DR

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| ZFS | Data integrity (checksumming) | T0 | L,C,P | No equivalent integrity guarantee from ext4/XFS; Ceph for distributed | Scrub reports, snapshot list, send/recv logs |
| Ceph (RBD/CephFS) | Distributed storage | T1 | C,P | GlusterFS possible but less mature; MinIO for object | OSD health, PG status, scrub results |
| restic / borg | Backup (encrypted, deduplicated) | T0 | L,C,P | Interchangeable; must support encryption + verification | Backup manifests, verification hashes |
| Velero + CSI snapshots | K8s backup/DR | T0 | C,P | Kasten acceptable; must support scheduled + on-demand + tested restores | Backup/restore logs, periodic restore test evidence |
| pgBackRest | PostgreSQL backup | T0 | C,P | pg_basebackup as fallback; pgBackRest for WAL archiving + PITR | Backup catalog, WAL archive verification |

## 8 — Data and integration services

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| PostgreSQL | Primary data store | T0 | C,P | No substitute for primary RDBMS; version-pinned | WAL, replication status, backup verification |
| Redis | Cache / ephemeral state | T1 | C,P | Valkey/KeyDB acceptable; must not hold durable state without backup | — |
| NATS / RabbitMQ / Kafka | Messaging | T1 | C,P | Choose per pattern (NATS for lightweight, Kafka for durable stream); not freely interchangeable | Message delivery metrics, consumer lag |
| OpenSearch / Elasticsearch | Search + log backend | T1 | C,P | Interchangeable; license implications differ | Index lifecycle logs |

## 9 — HPC / GPU

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Slurm | Job scheduling + accounting | T1 | L | PBS/Torque possible; Slurm dominant in HPC | Job accounting logs, fairshare records |
| NVIDIA CUDA/NCCL/DCGM | GPU compute + health monitoring | T0 | L,P | ROCm for AMD; not interchangeable per hardware | XID logs, ECC error counts, thermal records |
| Apptainer / Singularity | HPC container runtime | T1 | L | OCI for services; Apptainer for HPC user-space | Container provenance logs |

## 10 — AI / LLMOps

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| MLflow | Experiment tracking + model registry | T1 | L,P | W&B acceptable; must support lineage, artifact signing, promotion gates | Experiment logs, model metadata, promotion records |
| vLLM / TGI / Ollama | Inference serving | T1 | L,P | Choose per model/latency; Ollama for local dev, vLLM/TGI for production throughput | Inference latency/error metrics |
| Qdrant | Vector DB (RAG) | T1 | L,P | Apache 2.0, purpose-built, already integrated via Open WebUI. OpenSearch k-NN as fallback where a separate vector DB dependency is undesirable. Milvus if billion-vector scale required. | Collection metadata, query latency |
| OTel for inference | Inference boundary monitoring | T0 | P | Non-negotiable; GenAI semantic conventions | Inference traces, token metrics, error rates |
| Eval harness (golden sets + red-team) | Output quality gate | T0 | L,P | Custom + lm-eval-harness; must include regression, jailbreak, bias checks | Eval reports per model release |
| Safety filters + guardrails | Output boundary enforcement | T0 | P | Must be runtime-enforceable contracts, not just prompts; input validation + output policy | Filter decision logs, block/pass rates |
| Kill-switch / degraded mode | Actuation boundary | T0 | P | Must exist; implementation varies (feature flag, circuit breaker, traffic shift) | Trigger logs, mode-change evidence |
| DVC (optional) | Dataset versioning | T2 | L | Git-native alternatives; only if dataset lineage is complex | Dataset version hashes |

## 11 — AI governance artifacts

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Model BOM (MBOM) | Model provenance | T0 | P | Format not yet standardized; CycloneDX MLBOM emerging | Signed model manifest (weights, arch, license, training digests) |
| Dataset BOM (DBOM) | Data provenance | T0 | P | Same; structured manifest with consent/retention metadata | Signed dataset manifest |
| Model card / data sheet / system card | Documentation boundary | T0 | P | IEEE/ISO templates emerging; must cover intended use, limitations, risk | Published cards per model version |
| Signed attestation chain | End-to-end lineage | T0 | P | dataset → training → eval → approval → deployment; SLSA-style | Attestation envelopes per release |
| Risk register (AI-specific) | Governance boundary | T0 | P | Mapped to ISO 42001 / AI Act / NIST AI RMF as applicable | Risk register entries with control linkage |

## 12 — Assurance tooling

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| STPA templates (Markdown) | Hazard analysis | T0 | P | FMEA/FTA supplementary; STPA primary for control-system hazards | UCA tables, loss scenarios, safety constraints |
| GSN assurance cases | Argument structure | T0 | P | CAE acceptable alternative; must produce structured claim-argument-evidence | Assurance case documents |
| TLA+ | Distributed protocol verification | T2 | L,P | Alloy for structural; both selective use only | Spec files, model-check results |
| Immutable evidence store (WORM/S3) | Evidence integrity | T0 | P | MinIO S3 with Object Lock (COMPLIANCE mode) on ZFS; any S3-compatible with object lock acceptable; retention policy required | Retention policy config, integrity verification logs |
| Evidence catalogue (OpenSearch) | Evidence metadata query | T1 | P | OpenSearch index over MinIO artifacts; ILM for retention; reconstructable from MinIO if lost | Evidence coverage metrics, query access logs |
| Tamper-evident logs | Audit trail integrity | T0 | P | Daily hash chain over evidence store + Rekor entries; must survive admin compromise | Log integrity verification results, chain verification |

## 13 — Operator workstation

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Ubuntu LTS | OS | T1 | W | Fedora/RHEL acceptable for workstation | — |
| VS Code / VSCodium | Editor/IDE | T2 | W | Neovim, JetBrains acceptable | — |
| tmux | Terminal multiplexer | T2 | W | screen acceptable | — |
| jq/yq, ripgrep, fd | CLI utilities | T2 | W | Freely substitutable | — |
| Obsidian / Markdown tooling | Notes / docs | T3 | W | Any Markdown-native tool | — |
| draw.io / Mermaid / PlantUML | Diagrams | T2 | W | Interchangeable; Mermaid preferred for Git-native | Diagram source in VCS |
| Bitwarden / 1Password | Password manager | T1 | W | Per org policy; must support MFA + audit log | — |

## 14 — Standards and frameworks (governance scaffolding)

These are not tools but determine which controls are mandatory. [I] {70} — exact applicability depends on org, sector, and risk tier.

| Framework | Scope trigger | Impact on stack |
|-----------|---------------|-----------------|
| ISO/IEC 27001 + 27002 | Any org with ISMS commitment | Controls map across §1–§7 |
| NIS2 / NISG 2026 | Essential/important entities in EU; Austrian transposition effective 2026-10-01 | Incident notification, supply chain, risk management |
| DORA | Financial sector (EU) | ICT risk, TLPT, third-party, resilience testing |
| GDPR / DSG | Any processing of EU personal data; Austrian DSG supplements | Data minimization, DPIA, breach notification, access controls |
| EU AI Act | High-risk AI systems (Annex III) | Technical documentation, logging, human oversight, post-market monitoring → §10–§11, §16 |
| CRA | Products with digital elements placed on EU market | SBOM, vulnerability handling, CVD, CE marking → §2, §8 |
| ISO/IEC 42001 | AI management system | Governance structure for §10–§11 |
| ISO/IEC 23894 | AI risk management | Risk register structure for §11 |
| NIST AI RMF | Voluntary / US-facing | Complementary to EU frameworks; map/govern/measure/manage |

## 15 — API management

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Kong (OSS) | External API admission (north-south) | T1 | C,P | Envoy Gateway acceptable; must support OIDC, rate limiting, request validation, plugin architecture | Access logs, rate limit decisions, API call metrics |
| Coraza WAF (Kong plugin) | L7 threat filtering | T1 | P | ModSecurity acceptable; must integrate with API gateway | WAF block/allow decisions |
| Cilium + mTLS | Service-to-service auth (east-west) | T0* | C,P | Istio/Linkerd if full mesh needed; Cilium mutual auth for lightweight mTLS. *T0 if NIS2 requires encrypted east-west; T2 otherwise. | mTLS handshake logs, policy decisions |
| LiteLLM Proxy | LLM routing + token budget + rate limiting | T1 | C,P | Custom proxy acceptable; must support model routing, token tracking, OpenAI-compatible API | Token usage per user/model, routing decisions |
| LLM safety filter (custom) | Input/output policy enforcement | T0 | P | No off-the-shelf OSS fully covers this; custom filters on LiteLLM or standalone | Filter decisions (block/redact/pass), trigger rates |

## 16 — AI workload governance (production serving)

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| OTel GenAI instrumentation | Inference observability | T0 | P | Non-negotiable — GenAI semantic conventions for every inference call | Traces with token counts, latency, finish reason |
| Prompt version control | Prompt/system prompt lineage | T1 | C,P | Git-based or LiteLLM config; must be versioned and auditable | Prompt version history in VCS |
| Red team / adversarial suite | Security validation | T0 | L,P | Custom + community jailbreak suites; OWASP LLM Top 10 coverage | Red team report, ATLAS coverage matrix |
| Kill-switch (feature flag) | Actuation boundary (emergency halt) | T0 | P | Flipt (Apache 2.0) or Unleash (Apache 2.0) or Argo Rollouts instant rollback | Kill-switch activation log |

## 17 — AI workload governance (training / fine-tuning)

| Component | Boundary enforced | Tier | Env | Substitution constraints | Evidence output |
|-----------|-------------------|------|-----|--------------------------|-----------------|
| Model signing (cosign) | Model artifact integrity | T0 | L,P | Same signing pipeline as container images | Signed model digest + Rekor entry |
| Quality gate (automated) | Promotion boundary | T0 | L,P | Custom script; must check metrics, fairness, reproducibility, SBOM scan | Gate pass/fail log per model version |
| Reproducibility check | Training integrity verification | T1 | L | Re-run subset with same inputs; verify metric delta within tolerance | Reproducibility report |
| DCGM / NVML health monitoring | GPU integrity during training | T0 | L | ROCm equivalents for AMD | GPU health log, ECC error counts |
| Checkpoint integrity (ZFS) | Training state integrity | T0 | L | ZFS checksumming on checkpoint storage | ZFS scrub reports, checkpoint hashes |

---

## Next steps

1. **Legal review** of ISMS policy set (Appendix F) — adapt to org-specific context; get board approval.
2. **Confirm NIS2 entity classification** with legal counsel and Austrian competent authority (BKA NIS-Office / BMI).
3. **Determine CRA role** — manufacturer, importer, or purely operator/deployer.
4. **Populate supporting documents** — risk register, asset inventory, ROPA, critical supplier list.
5. **Conduct first DPIAs** — AI inference, employee monitoring (if applicable).
6. **Build evidence pipeline** (Appendix C) — phases P1–P4 deliver core pipeline in 4–6 weeks.
7. **Deploy API gateway** (Appendix D) — Kong + LiteLLM phases P1–P3.
8. **Verification sprint** — confirm all T0 controls are in enforcing mode (Appendix C §3 table).
9. **First internal audit** — self-assessment against NIS2 Art 21 + ISO 27001 Annex A.
10. **Review tier assignments** — especially T0 vs T1 boundaries; these drive change management overhead.

---

*Generated from ChatGPT stack inventory (3 documents), restructured with tiering, boundary mapping, and substitution constraints. Extended with API management (§15), AI governance (§16–§17), and security controls from cross-document validation pass. All claims [I] unless noted. Confidence {80} on tier assignments; {70} on regulatory framework applicability.*
