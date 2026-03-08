# POL-02: Risk Management Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Approved by:** [Board / Executive management — name and date]
**Review cycle:** Annual + after significant changes
**Classification:** Internal

## Purpose

Define the process for identifying, assessing, treating, and monitoring information security risks.

## Scope

All information assets, systems, and processes subject to risk that could affect the confidentiality, integrity, or availability of organisational information.

## Policy statements

The organisation shall implement a formal risk management process covering the following areas.

## Risk assessment methodology

1. Asset identification and valuation (link to asset inventory in `registers/asset-inventory.md`)
2. Threat and vulnerability identification (STPA, STRIDE, threat intelligence)
3. Likelihood and impact assessment (qualitative: Low/Medium/High/Critical)
4. Risk level determination (likelihood × impact matrix)
5. Risk treatment: Accept / Mitigate / Transfer / Avoid
6. Residual risk acceptance by risk owner (documented)

## Risk appetite

| Tier | Residual risk tolerance | Approval authority |
|------|------------------------|-------------------|
| T0 (safety/integrity) | Low only | Board |
| T1 (operational) | Medium or lower | CISO |
| T2/T3 | Managed at department level | Team lead |

## Risk register

Maintained in `registers/risk-register.md`. Reviewed quarterly. Each entry: risk statement, owner, likelihood, impact, existing controls, treatment plan, residual risk, monitoring signal, evidence pointer.

## Management review

Quarterly review of risk register by CISO + management. Annual board-level review with sign-off. Minutes stored in evidence pipeline (`evidence/governance/`).

## Roles and responsibilities

- **Board / Executive management:** Accept residual risk for T0 systems; annual review sign-off.
- **CISO:** Maintain risk register; conduct quarterly reviews; report to management.
- **Risk owners:** Assess and treat risks in their domain; monitor residual risk.
- **All personnel:** Report identified risks and threats.

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.1, 21.2(f) | NIS2 Directive |
| ISO 27001:2022 Clause 6.1, 8.2 | ISO 27001 |
| SCF RSK-01, RSK-04 | Secure Controls Framework |
| GDPR Art 32, 35 | GDPR |
| CRA Annex I Part I | CRA |

## Review and approval

| Date | Version | Approved by | Signature |
|------|---------|-------------|-----------|
| YYYY-MM-DD | 1.0 | [Name, Title] | [Signature] |
