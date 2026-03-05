# POL-10: Change Management Policy

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

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(e) | NIS2 Directive |
| ISO 27001:2022 Clause 6.3, A.8.32 | ISO 27001 |
| SCF CHG-01 | Secure Controls Framework |
| CRA Annex I Part II (no security regression in updates) | CRA |
