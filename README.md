# platform-assurance

Governance-as-code framework for EU-regulated on-premises and hybrid platform operations.

## Purpose

This repository provides a structured, version-controlled governance artifact set for organisations operating on-premises and hybrid infrastructure under European regulatory requirements. It addresses the gap between regulatory obligations (NIS2, CRA, GDPR, EU AI Act) and the operational controls that must be enforced at the infrastructure layer — where compliance is either built in or bolted on after the fact.

The approach treats governance as code: auditable, directly mappable to regulatory requirements, and maintained alongside infrastructure-as-code rather than in disconnected spreadsheets or GRC tools.

The canonical machine-readable source now lives in `controls/catalog.yaml`, with rendered views under `docs/generated/` and an AI-facing artifact classification index in `artifact-index.yaml`.

## What's in the repository

The artifact set is organized into seven governance documents covering architecture, compliance, security, evidence, AI/API management, observability, and policy — plus supporting registers, templates, and an evidence pipeline implementation.

**Architecture.** A tiered platform Bill of Materials (§1–§17) inventorying every infrastructure component with its tier classification (T0 safety/integrity through T3 exploratory), the boundary it enforces, substitution constraints, and what evidence it produces for audit. The BOM is now paired with a canonical control catalog (`controls/catalog.yaml`) and generated control/applicability views under `docs/generated/`.

**Compliance.** A license audit classifying every component's license posture (OSS, BSL, open-core, proprietary). A regulatory mapping cross-referencing NIS2, CRA, and GDPR requirements against stack controls — including a gap analysis, an incident reporting decision tree covering the overlapping NIS2/CRA/GDPR notification timelines, and an evidence reuse map showing which single artifacts satisfy multiple frameworks simultaneously.

**Security.** A STRIDE-based security assessment per trust boundary (external edge, cluster internal, CI/CD pipeline, admin access, data at rest), identifying gaps at the tool/control/evidence layers and producing a ranked remediation plan.

**Evidence pipeline.** Architecture and implementation for a generate → sign → store evidence lifecycle. CI/CD evidence stages produce signed SBOMs, vulnerability scans, SLSA provenance, and evidence manifests. Runtime evidence flows through Fluent Bit/Vector to MinIO WORM storage with daily hash chains for tamper detection. Governance documents are signed and catalogued in OpenSearch for auditor query. Includes working CI stage definitions, hash chain scripts, and automated integrity verification.

**AI and API management.** Three AI workload tiers (local inference, production serving, training/fine-tuning) with trust boundary analysis at each tier. API management across north-south (Kong), east-west (Cilium mTLS), and LLM gateway (LiteLLM) layers. OWASP LLM Top 10 mapped to stack controls. Kill-switch and degraded mode patterns for production AI serving.

**Observability and IAM.** End-to-end request-to-evidence flow from identity assertion through authorization, service execution, and signed evidence capture. Keycloak IAM architecture with OIDC/MFA/RBAC. OTel-based observability pipeline with structured logging standards. SLI/SLO framework with burn-rate alerting. Forensic readiness design with correlation across identity, traces, and audit logs.

**ISMS policy set.** Ten information security policies (POL-01 through POL-10) cross-referenced to NIS2, ISO 27001:2022 Annex A, GDPR, CRA, Austrian DSG, NISG 2026, and the Secure Controls Framework. Each policy is a Markdown template ready for legal review and board approval. Supporting registers (risk, asset, ROPA, supplier) and templates (DPIA, incident report, DR test, access review, supplier assessment) are included.

## Design principles

**Boundary enforcement over perimeter defense.** Controls are enforced at infrastructure seams — ingestion, decision, actuation, resource allocation, admission, and recovery. Each boundary has explicit invariants, monitoring, and violation-handling logic including defined degraded modes.

**Evidence by design.** Every control must produce verifiable evidence of its operation. Evidence artifacts are signed (cosign/Sigstore), stored in WORM storage (MinIO with Object Lock in COMPLIANCE mode), timestamped against independent sources (Rekor transparency log), and catalogued for auditor query. If a control cannot be observed and measured, it is not a control.

**Regulatory traceability.** Each control maps bidirectionally to regulatory requirements. Given a control, you can identify which regulations require it; given a regulation, you can identify which controls satisfy it.

**Reversible-first change management.** All infrastructure changes follow a reversible-first default: canary deployments, phased rollouts, checkpointing, and explicit rollback procedures. Irreversible changes require additional approval gates and evidence capture.

**Degraded modes over hard failures.** Every component has a defined degraded mode and safe-halt condition. The absence of a degraded mode specification is treated as a design defect.

## Regulatory scope

| Framework | Scope |
|-----------|-------|
| NIS2 Directive (EU 2022/2555) | Essential and important entity obligations, incident reporting, supply chain security |
| NISG 2026 (Austrian transposition) | National NIS2 implementation, effective 2026-10-01 |
| Cyber Resilience Act (EU 2024/2847) | Product security requirements, SBOM, vulnerability handling |
| GDPR (EU 2016/679) / Austrian DSG | Data protection by design, DPIA, processing records |
| EU AI Act (EU 2024/1689) | Risk classification, conformity assessment, post-market monitoring |
| ISO/IEC 27001:2022 | ISMS structure, Annex A controls |
| Secure Controls Framework (SCF) | Cross-framework control mapping |

## Methodology

- **STPA (System-Theoretic Process Analysis)** for hazard identification at control boundaries
- **STRIDE** for threat modelling per trust boundary
- **Claims-Arguments-Evidence (CAE)** for structuring assurance cases
- **CACE (Changing Anything Changes Everything)** as a change management principle

Evidence is tagged by provenance: `[F]` verified fact, `[I]` inference, `[S]` heuristic — with confidence levels {50,70,80,90}.

## Canonical source and generated views

- `controls/catalog.yaml` — canonical machine-readable control source
- `controls/catalog.schema.json` — schema for control validation
- `artifact-index.yaml` — artifact classification for AI continuation context
- `docs/generated/control-catalog.md` — rendered control view
- `docs/generated/applicability-matrix.md` — date- and role-gated applicability view
- `docs/generated/consistency-report.md` — automated validation output
- `scripts/render_controls.py` — renders generated views
- `scripts/validate_repo.py` — validates schema, references, links, and shell syntax

## Validation

```bash
make render
make validate
```

## Getting started

1. Read `controls/catalog.yaml` — the canonical control source
2. Read `docs/architecture/stack-bom.md` and `docs/generated/control-catalog.md` — component + control views
3. Review `docs/generated/applicability-matrix.md` and `docs/compliance/regulatory-mapping.md` — understand what applies by date and role
4. Adapt `policies/` to your organisation; get legal review and board sign-off
5. Populate `registers/` — risk register, asset inventory, ROPA, supplier list
6. Implement the evidence pipeline starting with `evidence-pipeline/ci/evidence-stage.yml` and validate with `make validate`

See [CONTRIBUTING.md](CONTRIBUTING.md) for the review process, commit conventions, and branch model.

## Related

- [`cps-assurance`](https://github.com/rmednitzer/cps-assurance) — Governance-as-code for cyber-physical systems under EU product regulation (Machinery Regulation, CRA, IEC 61508, IEC 62443).

## License

[MIT](LICENSE)
