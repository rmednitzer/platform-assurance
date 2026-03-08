# POL-08: Secure Development Lifecycle Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + Engineering Lead
**Review cycle:** Annual

## SDLC phases

1. **Design:** threat model (STRIDE); security requirements
2. **Develop:** signed commits; lint + SAST in pre-commit; Gitleaks secret scanning
3. **Build:** hermetic CI; SBOM generation; Trivy scanning; SLSA provenance
4. **Test:** DAST; dependency scanning; policy-as-code (conftest)
5. **Deploy:** signed artifact admission (Kyverno); canary/progressive delivery
6. **Operate:** OTel instrumentation; Falco runtime monitoring; vulnerability SLAs
7. **Decommission:** data erasure; access revocation; archive records

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

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(e) | NIS2 Directive |
| ISO 27001:2022 A.8.25, A.8.8 | ISO 27001 |
| SCF TDA-01 | Secure Controls Framework |
| CRA Annex I Part I, Part II | CRA |
