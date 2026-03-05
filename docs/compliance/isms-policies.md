# Stack BOM — ISMS Policy Document Set (Appendix F)

**Date:** 2026-03-05
**Scope:** Repo-ready Markdown policy templates cross-referenced to NIS2 / CRA / GDPR, ISO 27001:2022, SCF controls, and Austrian national law.
**Status:** DRAFT TEMPLATES — require legal review, management approval, and board sign-off before operational use.

---

## Austrian national law status

**NISG 2026 (NIS2 transposition):** Published 2025-12-23 as Regierungsvorlage 308 d.B. Enters into force **2026-10-01** (9-month grace period). Until then, NISG 2018 remains in force covering ~100 designated operators. The NISG 2026 will expand scope to ~4,000 entities. [F — verified via Wavestone NIS2 tracker and Austrian government publications]

**DSG (Datenschutzgesetz, gesetz-10001597):** In force. Austrian national supplement to GDPR. Key additions: § 50 (logging of processing operations), § 25 (complaints procedure), and provisions on DPO designation for public bodies. [F — verified via RIS OGD]

**GDPR (EU 2016/679):** Directly applicable. No Austrian transposition needed (regulation, not directive). DSG supplements where GDPR allows member state flexibility. [F]

**CRA (EU 2024/2847):** Regulation — directly applicable. Phased application dates. Vulnerability/incident reporting obligations apply earlier than full conformity assessment. Exact dates: Unknown — verify on EUR-Lex. [S,80]

---

## Control framework cross-reference key

Each policy template includes references to:

- **NIS2 Art 21.2(x)** — NIS2 Directive article/paragraph
- **ISO 27001:2022 A.x.x** — Annex A control
- **ISO 27001:2022 Clause x** — Management system clause
- **SCF GOV-xx / RSK-xx / etc.** — Secure Controls Framework control ID
- **GDPR Art x** — GDPR article
- **CRA Annex I** — CRA essential requirement (where applicable)
- **DSG § x** — Austrian Datenschutzgesetz (where applicable)
- **NISG 2026** — Austrian NIS2 transposition (effective 2026-10-01)

---

## Policy document set (10 policies)

### POL-01: Information Security Policy

```markdown
# Information Security Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Approved by:** [Board / Executive management — name and date]
**Review cycle:** Annual + after significant changes
**Classification:** Internal

## Purpose
This policy establishes the organisation's commitment to information security
and defines the governance framework for protecting information assets.

## Scope
All information assets, systems, personnel, and third parties that process,
store, or transmit organisational data.

## Policy statements
1. The organisation shall maintain an information security management system (ISMS)
   appropriate to its context, including applicable legal, regulatory, and
   contractual requirements.
2. Information security objectives shall be established, measured, and reviewed
   at planned intervals.
3. Management shall demonstrate leadership and commitment to the ISMS.
4. Resources shall be allocated to implement and maintain the ISMS.
5. All personnel shall be aware of their information security responsibilities.

## Roles and responsibilities
- **Board / Executive management:** Approve this policy; oversee ISMS; accept residual risk.
- **CISO:** Operate the ISMS; report to management; coordinate security controls.
- **DPO:** Advise on data protection obligations; monitor GDPR compliance.
- **All personnel:** Comply with policies; report security events.

## Regulatory basis
[See cross-reference table below]

## Review and approval
| Date | Version | Approved by | Signature |
|------|---------|-------------|-----------|
| YYYY-MM-DD | 1.0 | [Name, Title] | [Signature] |
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(a) — policies on risk analysis and information system security | NIS2 Directive |
| NIS2 Art 20 — management body approval and oversight | NIS2 Directive |
| ISO 27001:2022 Clause 5.1 — leadership and commitment | ISO 27001 |
| ISO 27001:2022 Clause 5.2 — information security policy | ISO 27001 |
| ISO 27001:2022 A.5.1 — policies for information security | ISO 27001 Annex A |
| SCF GOV-01 — cybersecurity governance controls | SCF |
| SCF GOV-02 — establish policies, standards, procedures | SCF |
| GDPR Art 24 — responsibility of the controller | GDPR |
| GDPR Art 32 — security of processing | GDPR |
| NISG 2026 — cybersecurity risk management measures (transposing Art 21) | Austrian law (effective 2026-10-01) |

---

### POL-02: Risk Management Policy

```markdown
# Risk Management Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Review cycle:** Annual

## Purpose
Define the process for identifying, assessing, treating, and monitoring
information security risks.

## Risk assessment methodology
1. Asset identification and valuation (link to asset inventory)
2. Threat and vulnerability identification (STPA, STRIDE, threat intelligence)
3. Likelihood and impact assessment (qualitative: Low/Medium/High/Critical)
4. Risk level determination (likelihood × impact matrix)
5. Risk treatment: Accept / Mitigate / Transfer / Avoid
6. Residual risk acceptance by risk owner (documented)

## Risk appetite
- T0 (safety/integrity) risks: residual risk must be Low or accepted by Board
- T1 (operational) risks: residual risk must be Medium or lower
- T2/T3 risks: managed at department level

## Risk register
Maintained in version control (Markdown). Reviewed quarterly.
Each entry: risk statement, owner, likelihood, impact, existing controls,
treatment plan, residual risk, monitoring signal, evidence pointer.

## Management review
Quarterly review of risk register by CISO + management.
Annual board-level review with sign-off.
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.1 — risk management approach | NIS2 |
| NIS2 Art 21.2(f) — assess effectiveness of risk management | NIS2 |
| ISO 27001:2022 Clause 6.1 — actions to address risks and opportunities | ISO 27001 |
| ISO 27001:2022 Clause 8.2 — information security risk assessment | ISO 27001 |
| SCF RSK-01 — risk management programme | SCF |
| SCF RSK-04 — recurring risk assessments | SCF |
| GDPR Art 32 — appropriate technical and organisational measures | GDPR |
| GDPR Art 35 — DPIA (links to risk assessment for personal data processing) | GDPR |
| CRA Annex I Part I — security risk assessment for products | CRA |

---

### POL-03: Access Control Policy

```markdown
# Access Control Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Review cycle:** Annual

## Principles
1. Least privilege: users receive minimum access necessary for their role.
2. Need-to-know: access to data based on business need, not hierarchy.
3. Separation of duties: critical functions require multiple actors.
4. Default deny: access is denied unless explicitly granted.

## Identity and authentication
- All users authenticated via Keycloak (OIDC/SAML).
- MFA mandatory for all human users (TOTP or FIDO2/WebAuthn).
- Service accounts: Vault dynamic credentials; short-lived leases.
- SSH: key-based only; password authentication disabled.

## Authorization model
- Application: RBAC via Keycloak roles; ABAC via OPA where needed.
- Kubernetes: RBAC; least-privilege RoleBindings per namespace.
- Infrastructure: Vault policies; path-based ACLs.
- Network: Cilium NetworkPolicy; default-deny ingress and egress.

## Access lifecycle
- Provisioning: HR-triggered via Keycloak; approval required for elevated roles.
- Review: quarterly access review by team managers (evidence captured).
- Deprovision: same-day revocation on termination; automated via HR integration.

## Privileged access
- JIT access via Vault dynamic credentials.
- Break-glass procedure documented and tested.
- All privileged sessions logged (auditd + Vault audit + K8s API audit).

## Monitoring
- Failed auth monitoring (Keycloak events → Wazuh).
- Service account usage monitoring (Vault audit → alerting).
- RBAC drift detection (monthly automated check vs. Git baseline).
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(i) — HR security, access control, asset management | NIS2 |
| NIS2 Art 21.2(j) — MFA, continuous authentication | NIS2 |
| ISO 27001:2022 A.5.15 — access control | ISO 27001 |
| ISO 27001:2022 A.8.2 — privileged access rights | ISO 27001 |
| ISO 27001:2022 A.8.5 — secure authentication | ISO 27001 |
| SCF IAC-01 — access control mechanisms | SCF |
| GDPR Art 25 — data protection by design and by default | GDPR |
| GDPR Art 32 — appropriate security measures | GDPR |
| DSG § 50 — logging of processing operations | Austrian DSG |

---

### POL-04: Incident Response Policy

```markdown
# Incident Response Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Review cycle:** Annual + after every major incident

## Classification
- P1 (Critical): Service outage, data breach, active compromise
- P2 (High): Degraded service, suspected compromise, policy violation
- P3 (Medium): Anomaly detected, non-critical vulnerability exploited
- P4 (Low): Minor event, no business impact

## Roles
- Incident Commander (IC): CISO or delegate
- Technical Lead: Senior engineer on-call
- Communications Lead: Coordinates with management, legal, regulators
- Scribe: Documents timeline and decisions

## Response phases
1. Detection (Wazuh, Falco, Alertmanager, user report)
2. Triage and classification (IC assigns severity)
3. Containment (isolate affected systems; preserve evidence)
4. Eradication (remove threat; patch vulnerability)
5. Recovery (restore service; verify integrity)
6. Post-incident review (blameless postmortem within 5 business days)

## Regulatory notification chain
- NIS2 (NISG 2026): 24h early warning → 72h notification → 1mo final report
  to Austrian CSIRT (CERT.at / competent authority)
- GDPR (Art 33/34): 72h to DPA (Datenschutzbehörde) if personal data affected
  and risk to individuals not unlikely; notify data subjects if high risk
- CRA (if manufacturer): 24h → 72h → 14d to ENISA
  for actively exploited product vulnerabilities

All three chains can fire simultaneously. Single intake → triage →
parallel notification. Coordination between CISO, DPO, and legal counsel.

## Evidence preservation
- Forensic images before containment actions
- All actions timestamped (chrony-synced)
- Evidence → MinIO WORM (evidence/incidents/{incident-id}/)
- Chain of custody documented

## Testing
- Annual tabletop exercise (P1 scenario)
- Semi-annual notification chain test (24h/72h workflow)
- Evidence: exercise report with findings and CAPA
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(b) — incident handling | NIS2 |
| NIS2 Art 23 — incident reporting (24h/72h/1mo) | NIS2 |
| ISO 27001:2022 A.5.24 — incident management planning | ISO 27001 |
| ISO 27001:2022 A.5.25 — assessment of information security events | ISO 27001 |
| ISO 27001:2022 A.5.26 — response to information security incidents | ISO 27001 |
| ISO 27001:2022 A.6.8 — information security event reporting | ISO 27001 |
| SCF IRO-01 — incident response operations | SCF |
| GDPR Art 33 — notification to supervisory authority | GDPR |
| GDPR Art 34 — communication to data subjects | GDPR |
| CRA Annex I Part II — vulnerability reporting to ENISA | CRA |
| NISG 2026 — incident reporting to Austrian CSIRT | Austrian law (effective 2026-10-01) |
| NISG 2018 § 19 — incident reporting (current law for designated operators) | Austrian law (in force) |

---

### POL-05: Business Continuity and Disaster Recovery Policy

```markdown
# Business Continuity and Disaster Recovery Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + Operations Lead
**Review cycle:** Annual

## RTO/RPO targets
| Service tier | RTO | RPO | Example services |
|-------------|-----|-----|-----------------|
| Critical | 4 hours | 1 hour | Authentication (Keycloak), primary DB (PostgreSQL) |
| Important | 24 hours | 4 hours | CI/CD pipeline, monitoring |
| Standard | 72 hours | 24 hours | Development tools, documentation |

## Backup strategy
- 3-2-1 rule: 3 copies, 2 different media, 1 off-site
- Encryption: all backups encrypted at rest (restic/borg)
- Immutability: at least one backup target is immutable (MinIO WORM or ZFS snapshot)
- Tools: restic/borg (general), pgBackRest (PostgreSQL), Velero (Kubernetes), ZFS send/receive

## Testing
- Monthly: restore test of one critical service (rotating)
- Quarterly: full DR scenario exercise
- Evidence: restore test log (time, data verification, RTO measured)

## Activation criteria
- [Criteria for declaring a disaster]
- [Escalation chain: who declares, who authorises failover]
- [Communication plan: internal, external, regulatory]
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(c) — business continuity, backup management, disaster recovery, crisis management | NIS2 |
| ISO 27001:2022 A.5.29 — information security during disruption | ISO 27001 |
| ISO 27001:2022 A.5.30 — ICT readiness for business continuity | ISO 27001 |
| ISO 27001:2022 A.8.13 — information backup | ISO 27001 |
| ISO 27001:2022 A.8.14 — redundancy of information processing facilities | ISO 27001 |
| SCF BCD-01 — business continuity management | SCF |
| CRA Annex I Part I — resilience against DoS | CRA |
| GDPR Art 32(1)(b) — ability to restore availability and access to personal data | GDPR |

---

### POL-06: Cryptography and Key Management Policy

```markdown
# Cryptography and Key Management Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Review cycle:** Annual

## Approved algorithms
- Symmetric: AES-256 (GCM or CBC with HMAC)
- Asymmetric: RSA ≥3072-bit; ECDSA P-256/P-384; Ed25519
- Hashing: SHA-256, SHA-384, SHA-512 (no MD5, no SHA-1)
- TLS: 1.2 minimum; 1.3 preferred; weak ciphers disabled

## Key management
- Key generation: cryptographically secure RNG only
- Key storage: Vault/OpenBao; hardware tokens (YubiKey) for human keys
- Key rotation: TLS certificates via cert-manager (automated); Vault dynamic secrets (lease-based)
- Key destruction: crypto-erase + documented destruction record

## Data at rest
- Database: PostgreSQL TDE or application-layer encryption via Vault Transit
- Storage: ZFS native encryption or LUKS on volumes with sensitive data
- Backups: restic/borg encryption (default)
- Evidence store: MinIO server-side encryption

## Data in transit
- External: TLS 1.2+ at Ingress
- East-west: Cilium mTLS or Istio/Linkerd mTLS
- Replication: encrypted ZFS send; TLS for Ceph

## Signing
- Code: GPG/SSH signed commits (enforced by GitLab)
- Artifacts: cosign (Sigstore keyless in CI; key-based as fallback)
- Evidence: cosign blob-sign; GPG for governance docs
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(h) — policies on cryptography and encryption | NIS2 |
| ISO 27001:2022 A.8.24 — use of cryptography | ISO 27001 |
| SCF CRY-01 — cryptographic controls | SCF |
| GDPR Art 32(1)(a) — pseudonymisation and encryption | GDPR |
| CRA Annex I Part I — protection of data at rest and in transit | CRA |

---

### POL-07: Supply Chain Security Policy

```markdown
# Supply Chain Security Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + Procurement
**Review cycle:** Annual

## Supplier classification
- Critical: failure causes significant incident (defined per NIS2 Art 23)
- Standard: non-critical; managed with baseline controls

## Due diligence (per critical supplier)
- Security questionnaire or ISO 27001/SOC 2 certificate
- Contractual security requirements (right-to-audit, incident notification SLA,
  data handling, sub-contractor approval, exit provisions)
- SBOM requested for software suppliers
- Annual review cadence

## Software supply chain
- SBOM: generated by Syft (CycloneDX + SPDX); attached to every release
- Signing: cosign (Sigstore); SLSA provenance attestations
- Admission: Kyverno policy requires signature + provenance + SBOM at deployment
- Vulnerability: Trivy + osv-scanner; VEX for triage documentation
- Update: Renovate for automated dependency updates

## GDPR processor management (Art 28)
- DPA for every processor relationship
- Sub-processor notification clause
- Audit rights exercised annually for critical processors
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(d) — supply chain security including direct suppliers | NIS2 |
| ISO 27001:2022 A.5.19–A.5.22 — supplier relationships | ISO 27001 |
| SCF TPM-01 — third-party management | SCF |
| CRA Annex I Part II — SBOM, vulnerability handling, CVD | CRA |
| GDPR Art 28 — processor agreements | GDPR |

---

### POL-08: Secure Development Lifecycle Policy

```markdown
# Secure Development Lifecycle Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + Engineering Lead
**Review cycle:** Annual

## SDLC phases
1. Design: threat model (STRIDE); security requirements
2. Develop: signed commits; lint + SAST in pre-commit
3. Build: hermetic CI; SBOM generation; Trivy scanning; SLSA provenance
4. Test: DAST; dependency scanning; policy-as-code (conftest)
5. Deploy: signed artifact admission (Kyverno); canary/progressive delivery
6. Operate: OTel instrumentation; Falco runtime monitoring; vulnerability SLAs
7. Decommission: data erasure; access revocation; archive records

## Vulnerability management SLAs
| Severity | Patch deadline | Verification |
|----------|---------------|--------------|
| Critical | 72 hours | Re-scan confirms fix |
| High | 14 days | Re-scan confirms fix |
| Medium | 30 days | Next release |
| Low | 90 days | Next release |

## Vulnerability disclosure
- Public CVD policy published (ISO 29147 aligned)
- CRA: report actively exploited vulns to ENISA within 24h
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(e) — security in acquisition, development, maintenance; vulnerability handling | NIS2 |
| ISO 27001:2022 A.8.25 — secure development lifecycle | ISO 27001 |
| ISO 27001:2022 A.8.8 — management of technical vulnerabilities | ISO 27001 |
| SCF TDA-01 — secure development practices | SCF |
| CRA Annex I Part I — secure-by-default; no known exploitable vulnerabilities | CRA |
| CRA Annex I Part II — vulnerability handling, CVD, ENISA reporting | CRA |

---

### POL-09: Data Classification and Handling Policy

```markdown
# Data Classification and Handling Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + DPO
**Review cycle:** Annual

## Classification levels
| Level | Definition | Examples |
|-------|-----------|---------|
| Public | No restriction; loss causes no harm | Published docs, marketing |
| Internal | Organisation-internal; loss causes minor harm | Internal comms, meeting notes |
| Confidential | Restricted; loss causes significant harm | Financial data, contracts, system configs |
| Restricted | Highly restricted; loss causes severe harm | Personal data (special category), secrets, keys, credentials |

## Handling rules per classification
| Control | Internal | Confidential | Restricted |
|---------|----------|-------------|------------|
| Encryption at rest | Recommended | Required | Required (Vault Transit or ZFS encryption) |
| Encryption in transit | Required (TLS) | Required (TLS 1.2+) | Required (mTLS) |
| Access control | RBAC | RBAC + need-to-know | RBAC + need-to-know + approval |
| Logging | Standard | Enhanced (access logged) | Full audit (all operations logged) |
| Backup encryption | Required | Required | Required |
| Disposal | Standard delete | Secure delete | Crypto-erase + documented destruction |

## Personal data (GDPR overlay)
- All personal data classified Confidential minimum
- Special category data (Art 9): classified Restricted
- ROPA maintained per GDPR Art 30
- DPIA required for high-risk processing (Art 35)
- Data minimisation applied at design stage (Art 25)
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(i) — asset management | NIS2 |
| ISO 27001:2022 A.5.12 — classification of information | ISO 27001 |
| ISO 27001:2022 A.5.13 — labelling of information | ISO 27001 |
| SCF DCL-01 — data classification | SCF |
| GDPR Art 5(1)(c) — data minimisation | GDPR |
| GDPR Art 5(1)(f) — integrity and confidentiality | GDPR |
| GDPR Art 25 — data protection by design and by default | GDPR |
| GDPR Art 30 — records of processing activities (ROPA) | GDPR |
| DSG § 50 — logging of processing operations | Austrian DSG |

---

### POL-10: Change Management Policy

```markdown
# Change Management Policy

**Version:** 1.0 DRAFT
**Owner:** Operations Lead
**Review cycle:** Annual

## Change categories
| Category | Approval | Lead time | Examples |
|----------|----------|-----------|---------|
| Standard | Pre-approved (pipeline-driven) | Immediate | Dependency update via Renovate; config change via GitOps |
| Normal | Peer review + team lead approval | 48h minimum | New service deployment; infra change; policy update |
| Emergency | IC or on-call lead approval | Immediate | Security patch; incident remediation |

## Required elements (all changes)
- Description and rationale
- Blast radius assessment (what could break; who is affected)
- Rollback plan (exact steps + time estimate)
- Verification criteria (how to confirm success)
- Stop conditions (when to abort)
- Evidence capture plan

## GitOps enforcement
- All changes via Git (merge request → review → merge → Argo CD sync)
- No manual kubectl/SSH changes in production (enforced via RBAC)
- Drift detection via Argo CD (alert on out-of-sync)

## Post-change verification
- Smoke tests (automated)
- SLO burn rate check (30-minute window)
- Rollback if burn rate exceeds threshold
```

**Cross-references:**

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(e) — security in maintenance of network and information systems | NIS2 |
| ISO 27001:2022 Clause 6.3 — planning of changes | ISO 27001 |
| ISO 27001:2022 A.8.32 — change management | ISO 27001 |
| SCF CHG-01 — change management programme | SCF |
| CRA Annex I Part II — security updates (no regression in security) | CRA |

---

## Supporting documents (not policies, but required records)

These are maintained alongside the policies and stored in the evidence pipeline:

| Document | Owner | Frequency | Cross-reference |
|----------|-------|-----------|-----------------|
| Risk register | CISO | Quarterly review + event-driven | POL-02; NIS2 Art 21.1; ISO 27001 Clause 8.2 |
| Asset inventory | Operations | Continuous + annual validation | POL-09; NIS2 Art 21.2(i); ISO 27001 A.5.9 |
| ROPA | DPO | Quarterly review | POL-09; GDPR Art 30; DSG |
| Access review records | Team managers | Quarterly | POL-03; NIS2 Art 21.2(i); ISO 27001 A.5.18 |
| Training records | HR / CISO | Annual + event-driven | NIS2 Art 20 + 21.2(g); ISO 27001 A.6.3 |
| Internal audit reports | Internal auditor / CISO | Annual + event-driven | ISO 27001 Clause 9.2; NIS2 Art 21.2(f) |
| Management review minutes | Board secretary | Annual minimum | ISO 27001 Clause 9.3; NIS2 Art 20 |
| Supplier assessment records | Procurement / CISO | Annual per critical supplier | POL-07; NIS2 Art 21.2(d); GDPR Art 28 |
| Incident reports | IC | Per incident | POL-04; NIS2 Art 23; GDPR Art 33 |
| BC/DR exercise reports | Operations | Quarterly | POL-05; NIS2 Art 21.2(c) |
| DPIA records | DPO | Per high-risk processing activity | GDPR Art 35 |

---

## Gap closure summary

| Gap (from previous assessment) | Closed by | Status |
|-------------------------------|-----------|--------|
| #1 ISMS policy document set | POL-01 through POL-10 | Template ready; needs legal review + board approval |
| #2 Incident response plan | POL-04 | Template ready; needs role assignment + first tabletop exercise |
| #3 BC/DR plan | POL-05 | Template ready; needs RTO/RPO validation per service |
| #4 Asset inventory | POL-09 (data classification) + supporting docs table | Structure defined; needs initial population |
| #5 DPIA for AI/monitoring | POL-09 (GDPR overlay) + supporting docs table | Process defined; DPIAs need to be conducted |
| #6 Supplier assessment programme | POL-07 | Template ready; needs critical supplier list + first assessments |
| #7 Management training records | Supporting docs table | Process defined; needs first training session |
| #8 Internal audit programme | Supporting docs table | Calendar needed; first audit can be self-assessment against Art 21 |
| #9 Change management procedure | POL-10 | Template ready; already partially enforced via GitOps |
| #10 Data classification scheme | POL-09 | Defined; needs per-system classification exercise |

---

## Implementation sequence

1. **Week 1–2:** Legal review of all 10 policy templates; adapt to org-specific context
2. **Week 2–3:** Board review and approval (POL-01 first, then batch remaining)
3. **Week 3–4:** Populate supporting documents (risk register, asset inventory, ROPA, supplier list)
4. **Week 4–5:** Conduct first DPIAs (AI inference, employee monitoring if applicable)
5. **Week 5–6:** First management training session; record attendance
6. **Week 6–8:** First internal audit (self-assessment against NIS2 Art 21 + ISO 27001 Annex A)
7. **Ongoing:** Quarterly review cycle; all approved policies and records signed (GPG/cosign) and uploaded to evidence store (MinIO WORM `evidence/governance/{year}/`) per Appendix C §2.3; catalogued in OpenSearch per Appendix C §5

**Evidence storage for governance documents:** Every approved policy version and supporting document (signed PDF or signed Git tag) flows into the evidence pipeline: `evidence/governance/{year}/POL-{nn}-v{version}.md.sig`. Board approval minutes, training records, access review results, and DPIA records follow the same path. The evidence catalogue (OpenSearch) tags each with `framework_tags` and `claim_refs` for audit query.

---

*All policy templates [I,80]. Regulatory cross-references [S,80] — verify against current official texts. Austrian NISG 2026 provisions [S,75] — law published but not yet in force; verify final text on RIS after 2026-10-01. SCF control IDs verified against current SCF database.*
