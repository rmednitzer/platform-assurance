# Risk Register

**Owner:** CISO
**Review cycle:** Quarterly + event-driven
**Last reviewed:** YYYY-MM-DD
**Approved by:** [Name, Title]

## Risk entries

| ID | Risk statement | Owner | Likelihood | Impact | Risk level | Existing controls | Treatment | Residual risk | Monitoring signal | Evidence pointer | Status |
|----|---------------|-------|------------|--------|------------|-------------------|-----------|---------------|-------------------|------------------|--------|
| RSK-001 | [Example: Unauthorized access to production database via compromised service account] | [Owner] | Medium | High | High | Vault dynamic credentials; short lease TTL; quarterly access review | Mitigate: implement JIT access; reduce lease TTL to 15min | Low | Vault audit log: SA usage outside expected pattern | `evidence/runtime/{date}/vault/` | Open |
| RSK-002 | | | | | | | | | | | |

## Risk matrix

|  | **Low impact** | **Medium impact** | **High impact** | **Critical impact** |
|---|---|---|---|---|
| **Critical likelihood** | High | Critical | Critical | Critical |
| **High likelihood** | Medium | High | Critical | Critical |
| **Medium likelihood** | Low | Medium | High | Critical |
| **Low likelihood** | Low | Low | Medium | High |

## Review log

| Date | Reviewer | Changes | Next review |
|------|----------|---------|-------------|
| YYYY-MM-DD | [Name] | Initial creation | +3 months |
