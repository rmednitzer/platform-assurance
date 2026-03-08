# Stack BOM — Regulatory Mapping (Appendix B)

## NIS2 × CRA × GDPR → Stack Components

**Date:** 2026-03-05
**Frameworks:** NIS2 (EU 2022/2555), CRA (EU 2024/2847), GDPR (EU 2016/679)
**Status:** DRAFT — requirement IDs are [S,80]; verify against current official texts and Austrian national transposition before audit submission. See `controls/catalog.yaml` and `docs/generated/applicability-matrix.md` for date- and role-gated applicability predicates.

---

## Temporal applicability anchors

- **CRA Article 14 application:** 2026-09-11
- **CRA Chapter IV application:** 2026-06-11
- **CRA general application:** 2027-12-11
- **AI Act partial application:** 2025-02-02 and 2025-08-02
- **AI Act general application:** 2026-08-02
- **AI Act additional phased application:** 2027-08-02
- **Austrian NISG 2026 effective date:** 2026-10-01
- **Austrian transition window:** NISG 2018 remains relevant through 2026-09-30 for currently designated operators.

These dates should be modeled as predicates in the control catalog, not only as prose in this appendix.

---

## Assumptions

- **Entity profile:** Roman operates infrastructure for an organisation that is likely an **important entity** under NIS2 (ICT services, digital infrastructure, or critical product manufacturing — exact classification depends on employer/client sector and size). [S,70]
- **CRA applicability:** Applies if the organisation **manufactures or places products with digital elements on the EU market**. If purely an operator/deployer (not a manufacturer), CRA obligations fall on your suppliers, but you must perform supply chain due diligence. [I] {80}
- **GDPR applicability:** Applies to any processing of personal data. Universal for EU-based organisations. [F]
- **Member state:** Austria. National NIS2 transposition: NISG 2026 (Netz- und Informationssystemsicherheitsgesetz 2026). Specific Austrian implementing details: Unknown — verify with BKA NIS-Office / BMI as competent authorities. [S,70]

---

## 1 — Control domain crosswalk

The highest-leverage shared control is **a unified risk management process with a single risk register** — it satisfies NIS2 Article 21.1, CRA Annex I security risk assessment, and GDPR Article 32 + Article 35 (DPIA) simultaneously. [S,80]

| Control domain | NIS2 Art. 21 | CRA Annex I | GDPR | Stack BOM components that enforce it |
|----------------|-------------|-------------|------|--------------------------------------|
| **Risk management** | 21.1 — policies on risk analysis | Part I — no known exploitable vulns; security risk assessment | Art 32 — appropriate technical/organisational measures; Art 35 — DPIA | Risk register (Markdown/GRC), STPA templates (§12), Trivy/osv-scanner (§2) |
| **Access control / IAM** | 21.2(i) — HR security, access control, asset management | Part I — AuthN, AuthZ, least privilege | Art 25 — data protection by design; Art 32 | Keycloak (§1), Vault/OpenBao (§1), SELinux/AppArmor (§6), Kyverno admission (§2) |
| **Cryptography** | 21.2(h) — cryptography and encryption policies | Part I — data at rest and in transit encryption | Art 32(1)(a) — pseudonymisation and encryption | cert-manager (§1), Vault PKI (§1), SOPS+age (§1), Cilium mTLS (§3), Sigstore cosign (§2) |
| **Vulnerability management** | 21.2(e) — security in acquisition, development, maintenance | Part I — no known exploitable vulns; Part II — address vulns without delay | Art 32 — ongoing assessment of effectiveness | Trivy (§2), osv-scanner (§2), Grype, Renovate/Dependabot (§2), CycloneDX VEX (§2) |
| **Incident response** | 21.2(b) — incident handling; Art 23 — 24h/72h/1mo reporting | Part II — vuln reporting to ENISA 24h/72h/14d | Art 33 — 72h breach notification to DPA; Art 34 — data subject notification | Wazuh SIEM (§5), Falco (§5), auditd (§5), Prometheus/Alertmanager (§5), incident runbooks (§12) |
| **Business continuity / DR** | 21.2(c) — BCP, backup management, DR | Part I — resilience against DoS | — (not directly mandated, but Art 32(1)(b) — ability to restore availability) | Velero (§7), restic/borg (§7), pgBackRest (§7), ZFS snapshots (§7), Ceph (§7) |
| **Supply chain security** | 21.2(d) — supply chain security including direct suppliers | Part II — SBOM; component identification | Art 28 — processor agreements; sub-processor chain | Syft SBOM (§2), cosign signing (§2), in-toto attestations (§2), Kyverno admission enforcement (§2), ORT/SCA (§2) |
| **Secure development / SDLC** | 21.2(e) — security in development and maintenance | Part I — secure-by-default; minimal attack surface; secure updates | Art 25 — data protection by design and default | GitLab CI (§4), signed commits (§1), policy-as-code OPA/Kyverno (§2,§6), conftest (§6), Trivy IaC scanning (§6) |
| **Logging and audit trail** | 21.2(j) — MFA, continuous auth, secure comms | Part I — security event logging for incident detection | Art 5(2) — accountability; Art 30 — records | OTel (§5), Prometheus (§5), Loki/OpenSearch (§5), auditd/journald (§5), Wazuh FIM (§5), chrony time sync (§5) |
| **Network security** | 21.2(e) — network and information systems security | Part I — protection of attack surface; secure interfaces | Art 32 — appropriate security measures | Cilium network policy (§3), nftables (§4), Ingress TLS (§3), WireGuard VPN (§4) |
| **Multi-factor authentication** | 21.2(j) — explicit MFA requirement | Part I — AuthN, access control | Art 32 — appropriate measures (MFA recommended for sensitive data) | Keycloak MFA (§1), SSH key/FIDO2 (§1) |
| **Data minimisation** | — (not explicit) | Part I — minimal data collection | Art 5(1)(c) — data minimisation; Art 25 — DPbD | Application-level (not a stack component); GDPR ROPA process; log retention policies |
| **SBOM / software inventory** | 21.2(d) — supply chain (implies inventory) | Part II — **mandatory** machine-readable SBOM | — | Syft (§2), CycloneDX/SPDX (§2), cosign (§2), OCI registry with SBOM artifacts (§3) |
| **Management accountability** | Art 20 — management body approves measures, personal liability | — (manufacturer obligations, not governance structure) | Art 5(2) — accountability; Art 24 — controller responsibility | Governance process; board minutes; training records; risk register sign-off |
| **Training** | Art 20 — management cybersecurity training; 21.2(g) — basic cyber hygiene and training | — | Art 39 — DPO tasks include awareness raising | Training programme; records in evidence store (§12) |

[S,80] — verify requirement IDs against current official texts.

---

## 2 — Incident reporting timeline decision tree

NIS2, CRA, and GDPR have **different but overlapping** reporting obligations. A single incident can trigger all three.

```
Incident detected
  │
  ├─ Is personal data affected?
  │    YES → GDPR Art 33: notify DPA within 72h (unless unlikely to result in risk)
  │         → If high risk to individuals: Art 34 notify data subjects without undue delay
  │
  ├─ Is this a "significant incident" per NIS2?
  │    YES → NIS2 Art 23:
  │         → Early warning to CSIRT/competent authority: 24h
  │         → Incident notification: 72h
  │         → Final report: 1 month
  │
  ├─ Is this an actively exploited vulnerability in a product you manufacture?
  │    YES → CRA: notify ENISA
  │         → Early warning: 24h
  │         → Notification: 72h
  │         → Final report: 14 days
  │
  └─ All three can fire simultaneously.
     Resolution: single intake → triage → parallel notification to:
       (a) National CSIRT (NIS2)
       (b) DPA (GDPR)
       (c) ENISA (CRA, if product manufacturer)
     Share underlying event record; do NOT conflate the reports.
```

**Stack components supporting this workflow:**
Wazuh (detection/correlation), Falco (runtime anomaly), auditd/journald (forensic trail), Alertmanager (routing), incident runbooks (operational-workflows skill), evidence store WORM/S3 (§12), chrony (timestamp integrity).

---

## 3 — Gap analysis: what the BOM covers vs. what it doesn't

### Well covered by the stack

| Obligation | Coverage | Evidence source |
|------------|----------|-----------------|
| NIS2 Art 21.2(b) Incident handling | Strong | Wazuh + Falco + OTel + runbooks |
| NIS2 Art 21.2(c) Business continuity | Strong | Velero + restic/borg + ZFS + pgBackRest + tested restores |
| NIS2 Art 21.2(d) Supply chain security | Strong | Syft + cosign + in-toto + Kyverno admission + SBOM pipeline |
| NIS2 Art 21.2(e) Secure development | Strong | GitLab CI + signed commits + Trivy + policy-as-code + conftest |
| NIS2 Art 21.2(h) Cryptography | Strong | cert-manager + Vault PKI + SOPS/age + Cilium mTLS |
| NIS2 Art 21.2(j) MFA | Strong | Keycloak + SSH keys |
| CRA Annex I Part I (secure-by-design) | Strong (for infrastructure) | Admission enforcement + scanning + signing + mTLS |
| CRA Annex I Part II SBOM | Strong | Syft + CycloneDX/SPDX + OCI artifact storage |
| CRA Part II Vuln handling | Strong | Trivy + osv-scanner + VEX + Renovate |
| GDPR Art 32 Security measures | Strong | Full stack coverage across §1–§7 |
| GDPR Art 33/34 Breach notification | Moderate | Detection exists; **notification workflow and templates need to be formalised** |

### Gaps or weak coverage

| Obligation | Gap | Remediation | Effort | Priority |
|------------|-----|-------------|--------|----------|
| **NIS2 Art 21.1 — Documented risk management policy** | Stack provides controls but not the **policy document** itself | Write ISMS-equivalent risk management policy; link to risk register; get board sign-off | M | High |
| **NIS2 Art 20 — Management body training + personal liability acknowledgement** | No tooling covers this — it's a governance process | Establish annual management cybersecurity training; document attendance; board resolution acknowledging liability | S | High |
| **NIS2 Art 23 — Incident reporting chain (24h/72h/1mo)** | Detection exists; **notification workflow to Austrian CSIRT (CERT.at / GovCERT) is not formalised** | Build and test the reporting chain: detection → classification → 24h early warning → 72h notification → final report; assign owners | M | High |
| **NIS2 Art 21.2(d) — Supplier security assessments** | SBOM pipeline covers software supply chain; **contractual/questionnaire assessment of service providers is not in the stack** | Supplier assessment template, right-to-audit clauses, annual review cadence | M | Medium |
| **NIS2 Art 21.2(g) — Cyber hygiene training programme** | Not a stack component | Establish training programme with records; phishing tests; new-joiner onboarding | S | Medium |
| **CRA — Conformity assessment + CE marking** | Only applies if manufacturing products with digital elements; **no tooling for DoC generation or CE marking workflow** | If manufacturer: establish conformity assessment process; if not: ensure suppliers provide DoC | L (if applicable) | Medium |
| **CRA — Vulnerability disclosure policy (public)** | Not published | Publish CVD policy (ISO 29147 aligned); link to ENISA reporting workflow | S | High (if manufacturer) |
| **CRA — 5-year security update commitment** | Policy, not tooling | Document support period per product; integrate into release planning | S | Medium |
| **GDPR Art 30 — ROPA** | Not a stack component; needs a maintained register of processing activities | Maintain ROPA in version-controlled spreadsheet or GRC tool; review annually | M | High |
| **GDPR Art 35 — DPIA for high-risk processing** | Not a stack component; needed for AI/profiling/monitoring | Conduct DPIAs for ML inference, monitoring systems processing personal data; document in evidence store | M | High (if AI in prod) |
| **GDPR Art 28 — Processor agreements** | Contractual, not technical | Audit all DPAs against Art 28 checklist; remediate gaps; establish sub-processor notification workflow | M | High |
| **GDPR — Data subject rights workflows** | Not in stack | Establish access/erasure/portability request workflows with documented timelines | M | Medium |
| **GDPR — Log retention vs. data minimisation tension** | Logging is strong; **retention policies and legal basis for each log category are not documented** | Document per-log-category: what is logged, legal basis, retention period, deletion procedure | S | Medium |
| **GDPR — Transfer impact assessment (if non-EEA transfers)** | Only relevant if using non-EEA services/processors | Conduct TIA per transfer; document supplementary measures | M (if applicable) | High (if applicable) |

---

## 4 — Evidence reuse map

Single evidence items that satisfy multiple frameworks:

| Evidence artifact | NIS2 | CRA | GDPR | Produced by |
|-------------------|------|-----|------|-------------|
| Risk register with treatment plan | Art 21.1 | Annex I risk assessment | Art 32 + Art 35 DPIA | STPA templates + risk register (§12) |
| SBOM (signed, per release) | Art 21.2(d) supply chain | **Annex I Part II mandatory** | — | Syft + cosign + OCI registry (§2) |
| Vulnerability scan reports | Art 21.2(e) | Annex I Part I no known vulns | Art 32 | Trivy + osv-scanner (§2) |
| Incident response plan (tested) | Art 21.2(b) + Art 23 | Part II vuln reporting | Art 33/34 | Runbook templates (§12) + drill evidence |
| Penetration test report | Art 21.2(f) effectiveness assessment | Annex I Part I | Art 32 | External or internal pentest |
| Access control audit | Art 21.2(i) | Annex I Part I AuthN/AuthZ | Art 32 + Art 25 | Keycloak audit logs + RBAC review (§1) |
| Backup verification evidence | Art 21.2(c) | — | Art 32(1)(b) availability | Velero restore test logs + ZFS scrub reports (§7) |
| Logging configuration + retention policy | Art 21.2(j) | Annex I Part I event logging | Art 5(2) accountability + minimisation tension | OTel config + Loki/OpenSearch ILM (§5) |
| Management training records | Art 20 | — | Art 39 (DPO awareness) | Training platform / sign-off sheets |
| Supplier assessment records | Art 21.2(d) | Annex I Part II component ID | Art 28 DPA audit | Supplier questionnaires + DPA register |
| Board approval minutes | Art 20 management body | — | Art 5(2) accountability | Governance process |
| Signed build provenance | Art 21.2(d) | Annex I Part II | — | in-toto + SLSA + cosign (§2) |

---

## 5 — Conflict and tension points

| Tension | Resolution | Stack impact |
|---------|------------|--------------|
| **GDPR data minimisation vs. NIS2/CRA logging** | Log what is required for security; apply retention limits; pseudonymise where possible; document legal basis per log category (Art 6(1)(c) legal obligation for NIS2 logs; Art 6(1)(f) legitimate interest for operational logs) | Loki/OpenSearch ILM policies; log redaction pipeline (Fluent Bit/Vector transforms) |
| **NIS2 24h reporting vs. GDPR 72h** | NIS2 early warning (24h) goes to CSIRT; GDPR notification (72h) goes to DPA. If both apply, the 24h NIS2 clock drives the triage pace. Build one intake → parallel notification. | Single incident triage runbook with dual notification paths |
| **CRA SBOM disclosure vs. confidentiality** | CRA requires SBOM available to market surveillance authority on request (not necessarily public). Design SBOM to exclude personal data. Agree confidential sharing mechanism. | SBOM stored in OCI registry with access control; separate public-facing CVD policy |

---

## 6 — Next steps

1. **Confirm entity classification** — determine NIS2 essential vs. important with legal counsel and Austrian competent authority (BKA NIS-Office / BMI). [S,70]
2. **Determine CRA role** — manufacturer, importer, or purely operator/deployer? This changes whether CRA obligations are direct or flow-through via suppliers.
3. **Formalise the governance layer** — ISMS policy set (Appendix F) provides templates; requires legal review + board approval.
4. **Build the incident reporting chain** — single triage → parallel NIS2/GDPR/CRA notification with tested timelines (POL-04 in Appendix F).
5. **Document log retention legal basis** — resolve GDPR minimisation vs. NIS2 logging tension per log category (POL-09 in Appendix F).

---

*All requirement mappings [S,80] unless noted. Verify against current official texts (EUR-Lex), Austrian NISG 2026 transposition (effective 2026-10-01), and EDPB guidelines before audit submission. Render date- and role-specific views from `controls/catalog.yaml` before relying on this appendix as an audit artifact.*
