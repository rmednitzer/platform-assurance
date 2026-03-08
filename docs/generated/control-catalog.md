# Generated Control Catalog

This file is generated from `controls/catalog.yaml`. Edit the catalog, not this view.

Generated: 2026-03-08T11:42:13Z

## Control summary

| ID | Title | Boundary | Type | Owners | Evidence artifact |
|----|-------|----------|------|--------|-------------------|
| CTL-0001 | Federated IAM with MFA and auditable authorization | admission | normative | security, platform | access_review |
| CTL-0002 | Secrets management with revocation and audit trail | secret-boundary | normative | security, platform | secret-control-proof |
| CTL-0003 | Signed software supply chain with SBOM and provenance | admission | normative | platform, security | ci_evidence_manifest |
| CTL-0004 | Immutable evidence store with retention controls | recovery | normative | security, platform | evidence-integrity-report |
| CTL-0005 | Incident triage with parallel regulatory notification paths | recovery | normative | security, legal, privacy | incident-report |
| CTL-0006 | Logging legality, minimisation, and forensic correlation | decision | normative | security, privacy, platform | logging-control-proof |
| CTL-0007 | Backup, restore, and disaster recovery proof | recovery | normative | platform, security | dr-test-report |
| CTL-0008 | Supplier and processor assurance | admission | normative | procurement, legal, security | supplier-assessment |
| CTL-0009 | AI gateway policy, provenance, and kill switch | decision | approved-pattern | platform, security, product | ai-gateway-proof |
| CTL-0010 | Management accountability and cyber training evidence | governance | normative | executive, security, legal | governance-approval-record |

## CTL-0001 — Federated IAM with MFA and auditable authorization

- Status: draft
- Artifact type: normative
- Boundary: admission
- Objective: Enforce authenticated, least-privilege access with evidence of every privileged decision.
- Required capability: oidc_or_saml_identity_provider, mfa, rbac_or_abac, audit_log_export
- Approved patterns: Keycloak + FIDO2/WebAuthn + role model review
- Owners: security, platform
- Verification: `keycloak export health + access review evidence + privileged role diff approval`
- Evidence artifact: `access_review`
- Required files: access-review-report.json, reviewer-signoff.bundle
- Retention tier: governance_10y
- Exception process: Security owner approval with compensating controls and dated expiry.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21(2)(i) | operator, deployer | 2024-10-17 |  |  |
| NISG-AT | NISG 2026 national implementation | operator | 2026-10-01 |  |  |
| GDPR | Articles 25, 32 | controller, processor | 2018-05-25 |  |  |

## CTL-0002 — Secrets management with revocation and audit trail

- Status: draft
- Artifact type: normative
- Boundary: secret-boundary
- Objective: Prevent unmanaged static secrets and prove secret lifecycle control.
- Required capability: secret_lease_management, audit_backend, revocation
- Approved patterns: Vault or OpenBao with audit backend and dynamic credentials
- Owners: security, platform
- Verification: `vault lease list + revoke test + audit log signature verification`
- Evidence artifact: `secret-control-proof`
- Required files: secret-lease-report.json, revoke-test.log
- Retention tier: governance_10y
- Exception process: Break-glass approval, bounded lifetime, retrospective review.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21(2)(h) | operator | 2024-10-17 |  |  |
| GDPR | Article 32(1)(a) | controller, processor | 2018-05-25 |  |  |

## CTL-0003 — Signed software supply chain with SBOM and provenance

- Status: draft
- Artifact type: normative
- Boundary: admission
- Objective: Ensure deployed artifacts are traceable, signed, and accompanied by machine-readable inventory.
- Required capability: sbom_generation, vulnerability_scan, signature_verification, provenance_attestation
- Approved patterns: Syft + Trivy + cosign + in-toto/SLSA + Kyverno verifyImages
- Owners: platform, security
- Verification: `syft/trivy outputs present + cosign verify + kyverno admission test + provenance attestation lookup`
- Evidence artifact: `ci_evidence_manifest`
- Required files: sbom-cdx.json, sbom-spdx.json, vuln-report.json, evidence-manifest.json, manifest.bundle
- Retention tier: ci_3y
- Exception process: Change advisory approval with explicit risk acceptance and temporary policy override.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21(2)(d),(e) | operator | 2024-10-17 |  |  |
| CRA | Annex I Part II, Article 13, Article 14 | manufacturer, importer | 2026-09-11 |  |  |
| CRA | General application | manufacturer, importer, distributor | 2027-12-11 |  |  |

## CTL-0004 — Immutable evidence store with retention controls

- Status: draft
- Artifact type: normative
- Boundary: recovery
- Objective: Preserve audit and incident evidence against tampering and premature deletion.
- Required capability: object_lock_compliance_mode, retention_policies, independent_signature_or_timestamp
- Approved patterns: MinIO object lock COMPLIANCE + cosign bundles + Rekor lookup
- Owners: security, platform
- Verification: `mc retention info + chain verification + sample object lock immutability check`
- Evidence artifact: `evidence-integrity-report`
- Required files: chain-entry.txt, chain-hash.txt, chain-entry.bundle
- Retention tier: governance_10y
- Exception process: Not permitted without board-approved retention change and legal review.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21, Article 23 | operator | 2024-10-17 |  |  |
| CRA | Article 14, Annex I Part II | manufacturer | 2026-09-11 |  |  |
| GDPR | Articles 5(2), 30, 32, 33 | controller, processor | 2018-05-25 |  |  |

## CTL-0005 — Incident triage with parallel regulatory notification paths

- Status: draft
- Artifact type: normative
- Boundary: recovery
- Objective: Route a single incident record into the correct legal notifications with evidentiary continuity.
- Required capability: incident_classification, timed_notification_runbooks, evidence_preservation
- Approved patterns: Wazuh/Falco/Alertmanager + incident template + regulator-specific checklists
- Owners: security, legal, privacy
- Verification: `tabletop exercise record + notification timer drill + signed incident package`
- Evidence artifact: `incident-report`
- Required files: incident-report.md, notification-log.json, evidence-preservation-checklist.json
- Retention tier: incidents_5y
- Exception process: None for notification clocks; escalation required immediately on ambiguity.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 23 | operator | 2024-10-17 |  |  |
| NISG-AT | NISG 2018 transitional applicability | operator | 2018-12-29 | 2026-09-30 |  |
| NISG-AT | NISG 2026 effective date | operator | 2026-10-01 |  |  |
| GDPR | Articles 33, 34 | controller, processor | 2018-05-25 |  |  |
| CRA | Article 14 | manufacturer | 2026-09-11 |  |  |

## CTL-0006 — Logging legality, minimisation, and forensic correlation

- Status: draft
- Artifact type: normative
- Boundary: decision
- Objective: Preserve enough telemetry for security and audit without losing legal basis or retention discipline.
- Required capability: correlation_ids, structured_logging, retention_per_category, redaction_or_pseudonymisation
- Approved patterns: OTel + Loki/OpenSearch ILM + documented legal basis per log category
- Owners: security, privacy, platform
- Verification: `log schema check + retention policy export + redaction sample + access log correlation proof`
- Evidence artifact: `logging-control-proof`
- Required files: retention-policy-export.json, log-schema.json, correlation-sample.txt
- Retention tier: governance_10y
- Exception process: DPO and security sign-off for any retention override.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21(2)(j) | operator | 2024-10-17 |  |  |
| GDPR | Articles 5(1)(c), 5(1)(e), 5(2), 25, 32 | controller, processor | 2018-05-25 |  |  |

## CTL-0007 — Backup, restore, and disaster recovery proof

- Status: draft
- Artifact type: normative
- Boundary: recovery
- Objective: Demonstrate recoverability against defined RTO/RPO targets with signed restore evidence.
- Required capability: scheduled_backups, restore_tests, immutable_backup_metadata
- Approved patterns: Velero + restic/borg + pgBackRest + signed DR test reports
- Owners: platform, security
- Verification: `restore drill execution + RTO/RPO measurement + signed DR report upload`
- Evidence artifact: `dr-test-report`
- Required files: dr-test-report.md, restore-log.txt, timing-metrics.json
- Retention tier: dr_tests_5y
- Exception process: Risk acceptance only with compensating failover design and explicit expiry.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21(2)(c) | operator | 2024-10-17 |  |  |
| GDPR | Article 32(1)(b),(c) | controller, processor | 2018-05-25 |  |  |

## CTL-0008 — Supplier and processor assurance

- Status: draft
- Artifact type: normative
- Boundary: admission
- Objective: Prove third-party dependencies and processors are assessed before use and reviewed on cadence.
- Required capability: supplier_inventory, due_diligence_template, contractual_security_requirements
- Approved patterns: supplier register + supplier assessment template + Article 28 checklist
- Owners: procurement, legal, security
- Verification: `supplier register review + signed assessment + DPA presence check`
- Evidence artifact: `supplier-assessment`
- Required files: supplier-assessment.md, dpa-checklist.json
- Retention tier: governance_10y
- Exception process: Vendor risk acceptance signed by procurement, legal, and security.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 21(2)(d) | operator | 2024-10-17 |  |  |
| GDPR | Articles 28, 44-49 | controller, processor | 2018-05-25 |  |  |
| CRA | Annex I Part II | manufacturer | 2027-12-11 |  |  |

## CTL-0009 — AI gateway policy, provenance, and kill switch

- Status: draft
- Artifact type: approved-pattern
- Boundary: decision
- Objective: Keep AI/API traffic governed through an explicit policy and provenance boundary.
- Required capability: model_routing_control, prompt_and_response_logging_policy, emergency_disable, evaluation_gate
- Approved patterns: LiteLLM proxy + feature flag kill switch + eval harness + model provenance log
- Owners: platform, security, product
- Verification: `kill-switch drill + gateway policy export + evaluation bundle lookup`
- Evidence artifact: `ai-gateway-proof`
- Required files: gateway-policy.json, kill-switch-test.log, eval-summary.json
- Retention tier: governance_10y
- Exception process: AI governance review board approval.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| AI-Act | Article 8 risk management and applicable downstream obligations by system classification | provider, deployer | 2026-08-02 |  | Only when the system falls in a regulated AI Act risk class or uses GPAI obligations. |
| GDPR | Articles 25, 35 | controller, processor | 2018-05-25 |  | When AI workloads process personal data. |

## CTL-0010 — Management accountability and cyber training evidence

- Status: draft
- Artifact type: normative
- Boundary: governance
- Objective: Prove management review, accountability, and training for regulated cyber obligations.
- Required capability: management_signoff, training_records, review_cadence
- Approved patterns: board approval minutes + annual training register + policy review workflow
- Owners: executive, security, legal
- Verification: `signed board minutes + training attendance export + annual review ticket closure`
- Evidence artifact: `governance-approval-record`
- Required files: board-minutes.pdf, training-attendance.csv
- Retention tier: governance_10y
- Exception process: Not waivable; escalate to board secretary and CISO.

### Applicability
| Framework | Regulatory reference | Roles | From | Until | Condition |
|-----------|----------------------|-------|------|-------|-----------|
| NIS2 | Article 20 | operator | 2024-10-17 |  |  |
| NISG-AT | NISG 2026 management obligations | operator | 2026-10-01 |  |  |
