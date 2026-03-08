# POL-04: Incident Response Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Approved by:** [Board / Executive management — name and date]
**Review cycle:** Annual + after every major incident
**Classification:** Internal

## Purpose

Establish the incident response process to detect, contain, eradicate, and recover from security incidents while meeting regulatory notification obligations.

## Scope

All security incidents, near-misses, and events that may affect the confidentiality, integrity, or availability of organisational systems or data.

## Policy statements

The organisation shall maintain an incident response capability covering the following areas.

## Classification

| Severity | Definition | Response time |
|----------|-----------|---------------|
| P1 (Critical) | Service outage, data breach, active compromise | Immediate |
| P2 (High) | Degraded service, suspected compromise, policy violation | < 1 hour |
| P3 (Medium) | Anomaly detected, non-critical vulnerability exploited | < 4 hours |
| P4 (Low) | Minor event, no business impact | Next business day |

## Roles and responsibilities

- **Incident Commander (IC):** CISO or delegate
- **Technical Lead:** Senior engineer on-call
- **Communications Lead:** Coordinates with management, legal, regulators
- **Scribe:** Documents timeline and decisions

## Response phases

1. **Detection** (Wazuh, Falco, Alertmanager, user report)
2. **Triage and classification** (IC assigns severity)
3. **Containment** (isolate affected systems; preserve evidence)
4. **Eradication** (remove threat; patch vulnerability)
5. **Recovery** (restore service; verify integrity)
6. **Post-incident review** (blameless postmortem within 5 business days; template: `templates/incident/`)

## Regulatory notification chain

| Framework | Timeline | Recipient | Trigger |
|-----------|----------|-----------|---------|
| NIS2 / NISG 2026 | 24h early warning → 72h notification → 1mo final report | Austrian CSIRT (CERT.at / competent authority) | Significant incident per NIS2 Art 23 |
| GDPR / DSG | 72h to DPA; data subjects if high risk | Datenschutzbehörde (AT DPA) | Personal data breach with risk to individuals |
| CRA | 24h → 72h → 14d to ENISA | ENISA | Actively exploited vulnerability in manufactured product |

All three chains can fire simultaneously. Single intake → triage → parallel notification. Coordination between CISO, DPO, and legal counsel.

## Evidence preservation

- Forensic images before containment actions
- All actions timestamped (chrony-synced)
- Evidence → MinIO WORM (`evidence/incidents/{incident-id}/`)
- Chain of custody documented

## Testing

- Annual tabletop exercise (P1 scenario)
- Semi-annual notification chain test (24h/72h workflow)
- Evidence: exercise report with findings and CAPA

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(b), Art 23 | NIS2 Directive |
| ISO 27001:2022 A.5.24, A.5.25, A.5.26, A.6.8 | ISO 27001 |
| SCF IRO-01 | Secure Controls Framework |
| GDPR Art 33, 34 | GDPR |
| CRA Annex I Part II | CRA |
| NISG 2026, NISG 2018 § 19 | Austrian law |

## Review and approval

| Date | Version | Approved by | Signature |
|------|---------|-------------|-----------|
| YYYY-MM-DD | 1.0 | [Name, Title] | [Signature] |
