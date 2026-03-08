# Stack BOM — Cross-Document Validation Report

**Date:** 2026-03-05
**Scope:** Full consistency pass across all 7 documents (BOM + Appendices A–F)
**Status:** Historical manual reconciliation artifact. Current source of truth for consistency checking is `scripts/validate_repo.py`, which renders `docs/generated/consistency-report.md`.

---

This document records the initial manual reconciliation pass. Treat `docs/generated/consistency-report.md` as the current validation artifact and `controls/catalog.yaml` as the canonical control source.

## Issues found and remediation

### Category 1: Missing components in main BOM

The main BOM (§1–§14) does not include components added in later appendices. These must be merged into the BOM to maintain it as the single source of truth.

| Component | Added in | Should be in BOM as | Status |
|-----------|----------|-------------------|--------|
| Kong (API gateway) | Appendix D §15 | New §15 — API management | **FIX: Add** |
| LiteLLM Proxy (LLM gateway) | Appendix D §15 | New §15 — API management | **FIX: Add** |
| Coraza WAF | Appendix C + D | New §15 — API management (Kong plugin) | **FIX: Add** |
| Gitleaks (secret scanning) | Appendix C | §6 — Security engineering | **FIX: Add** |
| Flipt/Unleash (feature flags) | Appendix D §16 | §16 — AI workload governance (kill-switch) | **FIX: Add** |
| MinIO (evidence store, WORM) | Appendix C | §12 — Assurance tooling (already partially referenced) | **FIX: Explicit row** |
| OpenSearch (evidence catalogue) | Appendix C §5 | §12 — Assurance tooling | **FIX: Explicit row** |

### Category 2: Terminology inconsistencies

| Issue | Location | Fix |
|-------|----------|-----|
| Appendix B says "NISG 2024" | Regulatory mapping §assumptions | **FIX: Update to NISG 2026** (law was published 2025-12-23 as NISG 2026, not 2024) |
| Appendix B footer says "Austrian NISG 2024 transposition" | Regulatory mapping footer | **FIX: Update to NISG 2026** |
| Evidence pipeline uses "Vault" throughout, never "OpenBao" | Appendix C §2 | **FIX: Change to "Vault/OpenBao"** to match BOM naming |
| Appendix E §4.1 says "Keycloak events" but Appendix F POL-04 says "Keycloak event listener → OTel / syslog" | Observability + ISMS | **OK: Compatible but different detail levels** |

### Category 3: Cross-reference alignment

| Issue | Location | Fix |
|-------|----------|-----|
| BOM §14 lists frameworks but does not reference NISG 2026 | Main BOM | **FIX: Add NISG 2026 row** |
| BOM "Next steps" section is stale — most items are now addressed by appendices | Main BOM | **FIX: Update next steps** |
| Appendix D §16–§17 define BOM additions but these are not in the main BOM file | Main BOM | **FIX: Merge §15–§17 into BOM** |
| Appendix C security assessment identifies Gitleaks + Coraza as needed but BOM lacks them | Main BOM §6 + new §15 | **FIX: Add to BOM** |
| License audit (Appendix A) does not cover Kong, LiteLLM, Coraza, Gitleaks, Flipt | Appendix A | **FIX: Add rows** |
| Appendix B gap analysis references "governance layer" gaps — now addressed by Appendix F | Appendix B | **FIX: Add note referencing Appendix F** |

### Category 4: Structural issues

| Issue | Location | Fix |
|-------|----------|-----|
| Evidence pipeline section numbering was patched manually — verify continuity | Appendix C | **Verified: §1–§8 sequential, OK** |
| Appendix E §8 says "no new tools" but Appendix D added Kong, LiteLLM etc. | Appendix E | **FIX: Clarify that Appendix E uses BOM components; new components are in Appendix D** |
| Main BOM has no document index / table of contents linking all appendices | Main BOM | **FIX: Add document index** |

### Category 5: Content gaps between documents

| Gap | Explanation | Fix |
|-----|-------------|-----|
| Appendix D defines OTel GenAI instrumentation but Appendix E observability architecture doesn't explicitly show GenAI spans in the OTel Collector pipeline | Appendix E §3.1 | **FIX: Add GenAI span routing in OTel Collector description** |
| Appendix F POL-09 defines data classification but Appendix E §4.1 retention table doesn't map to classification levels | Appendix E + F | **Minor: Add note that retention tiers align to classification** |
| Appendix C evidence pipeline stores governance docs but Appendix F doesn't specify how policy sign-off flows to evidence store | Appendix F | **FIX: Add evidence storage instruction to policy template** |
