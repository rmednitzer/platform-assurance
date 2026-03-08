# POL-10: Change Management Policy

**Version:** 1.0 DRAFT
**Owner:** Operations Lead
**Approved by:** [Board / Executive management — name and date]
**Review cycle:** Annual
**Classification:** Internal

## Purpose

Define the change management process to ensure all changes are assessed, approved, and tracked to prevent unintended disruption.

## Scope

All changes to production systems, infrastructure, policies, and configurations.

## Policy statements

The organisation shall manage changes in accordance with the following categories and procedures.

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

## Roles and responsibilities

- **Operations Lead:** Own change management process; approve normal changes.
- **Team leads:** Review and approve standard changes within their domain.
- **IC / on-call lead:** Approve emergency changes.
- **All personnel:** Follow change management procedures; document changes.

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(e) | NIS2 Directive |
| ISO 27001:2022 Clause 6.3, A.8.32 | ISO 27001 |
| SCF CHG-01 | Secure Controls Framework |
| CRA Annex I Part II (no security regression in updates) | CRA |
| GDPR Art 25, Art 32 (security of processing; change controls for personal data systems) | GDPR |

## Review and approval

| Date | Version | Approved by | Signature |
|------|---------|-------------|-----------|
| YYYY-MM-DD | 1.0 | [Name, Title] | [Signature] |
