# Full Repository Validation Report

**Date:** 2026-03-08
**Scope:** Complete governance repository validation — structure, policies, registers, templates, evidence pipeline, cross-references, and automated checks
**Status:** PASS with findings

---

## 1. Automated Validation (`make validate`)

**Result:** PASS

All five automated checks passed:

- Control catalog schema validation and uniqueness (10 controls, CTL-0001–CTL-0010)
- Artifact index file existence (37 entries)
- Local Markdown link integrity (all `.md` files)
- Stack BOM document index references
- Shell script syntax for evidence pipeline scripts

---

## 2. Repository Structure

**Result:** PASS

All files documented in `CLAUDE.md` exist at their specified paths. Additional undocumented files are present and consistent:

| Extra file/directory | Purpose |
|---------------------|---------|
| `Makefile` | Render and validate targets |
| `artifact-index.yaml` | Machine-readable artifact registry (37 entries) |
| `controls/catalog.yaml` | Canonical control catalog (10 controls) |
| `controls/catalog.schema.json` | JSON Schema for catalog validation |
| `scripts/validate_repo.py` | Automated consistency checker |
| `scripts/render_controls.py` | Generates Markdown from catalog |
| `docs/generated/consistency-report.md` | Auto-generated validation output |
| `docs/generated/control-catalog.md` | Rendered control catalog view |
| `docs/generated/applicability-matrix.md` | Rendered applicability matrix |

**Recommendation:** Update `CLAUDE.md` repository structure section to include these files.

---

## 3. Policy Validation (POL-01 through POL-10)

**Result:** FINDING — structural inconsistency across policies

All 10 policies are present, correctly numbered, and carry `1.0 DRAFT` status. All use British English spelling correctly and include cross-reference tables mapping to regulatory frameworks.

**POL-01 is the only fully compliant policy.** Policies POL-02 through POL-10 are missing standard structural elements:

| Missing element | Affected policies | Count |
|----------------|-------------------|-------|
| `Approved by` metadata field | POL-02 – POL-10 | 9 |
| `Classification` metadata field | POL-02 – POL-10 | 9 |
| Explicit `Purpose` section | POL-03 – POL-10 | 8 |
| Explicit `Scope` section | POL-02 – POL-10 | 9 |
| Explicit `Policy statements` section | POL-02 – POL-10 | 9 |
| `Roles and responsibilities` section | POL-02, POL-03, POL-05 – POL-10 | 8 |
| `Review and approval` log table | POL-02 – POL-10 | 9 |
| GDPR cross-reference in mapping table | POL-08, POL-10 | 2 |

All policies contain substantive, high-quality content — the issue is structural wrapper consistency, not content gaps.

---

## 4. Registers Validation

**Result:** PASS with one finding

| Register | Tabular format | Placeholders | Domain check | Overall |
|----------|---------------|-------------|-------------|---------|
| `asset-inventory.md` | PASS | PASS | N/A | PASS |
| `risk-register.md` | PASS | PASS | 3×4 matrix | FINDING |
| `ropa.md` | PASS | PASS | Art. 30 fields present | PASS |
| `supplier-register.md` | PASS | PASS | N/A | PASS |

**Finding:** The risk register has a **3×4 risk matrix** (3 likelihood levels × 4 impact levels). The `CLAUDE.md` specification states "4×4 matrix" but then enumerates only three likelihood levels (`Low/Medium/High`). This is an internal inconsistency in the specification. To achieve a true 4×4 matrix, a fourth likelihood level (e.g., `Critical`) would be needed.

---

## 5. Templates Validation

**Result:** PASS

All 5 templates passed all checks:

| Template | Prefix | Placeholders | No example data | Overall |
|----------|--------|-------------|----------------|---------|
| `TEMPLATE-access-review.md` | PASS | PASS | PASS | PASS |
| `TEMPLATE-dpia.md` | PASS | PASS | PASS | PASS |
| `TEMPLATE-dr-test-report.md` | PASS | PASS | PASS | PASS |
| `TEMPLATE-incident-report.md` | PASS | PASS | PASS | PASS |
| `TEMPLATE-supplier-assessment.md` | PASS | PASS | PASS | PASS |

---

## 6. Evidence Pipeline Validation

**Result:** PASS with one advisory

| Criterion | Result |
|-----------|--------|
| `set -euo pipefail` in all scripts | PASS |
| Valid GitLab CI YAML structure | PASS |
| Cosign signing references (sign + verify) | PASS |
| MinIO WORM / Object Lock COMPLIANCE mode | PASS |
| Hash chain algorithm consistency (collector ↔ verifier) | PASS |
| Evidence paths in MinIO, not local filesystem | PASS |

**Advisory:** The `CHAIN_PREFIX` variable is configurable in the collector (`daily-hash-chain.sh`, default `chain`) but hard-coded as `chain/` in the verifier (`verify-evidence.sh`). Overriding `CHAIN_PREFIX` without a corresponding verifier update would break chain verification. At default values this is not a problem.

---

## 7. Controls and Artifact Index

**Result:** PASS

- `controls/catalog.yaml` validates against `controls/catalog.schema.json` (JSON Schema Draft 2020-12)
- All 10 control IDs match `^CTL-[0-9]{4}$` pattern
- All required fields present per schema (13 fields per control)
- `artifact-index.yaml` covers all 37 repository files with correct paths
- Canonical source pointers are consistent (`controls/catalog.yaml` for derived docs)
- Makefile dependency chain (`validate` depends on `render`) ensures generated files exist before validation

---

## 8. Cross-Document Consistency

**Result:** PASS with known gaps

The historical manual validation report (`docs/architecture/validation-report.md`) documents 19 specific cross-document issues identified on 2026-03-05. These are tracked as remediation items and do not represent regressions. The automated validator (`scripts/validate_repo.py`) covers structural consistency; the manual report covers semantic consistency.

Key areas validated:
- Stack BOM tiering model (T0–T3) correctly applied across all 17 sections
- Regulatory mapping includes bidirectional traceability (NIS2, CRA, GDPR forward and reverse)
- ISMS policies document references all 10 policies correctly
- Security assessment uses STRIDE across 5 trust boundaries (TB1–TB5)
- AI API management covers all 3 workload tiers and all 10 OWASP LLM threats
- Observability document covers OTel pipeline, IAM (Keycloak), and SLI/SLO framework
- License audit covers all BOM sections with risk flags for BSL/AGPL components
- Controls catalog (10 controls) validates against JSON Schema with unique IDs

### Documentation vs implementation discrepancies

| # | Location | Discrepancy |
|---|----------|-------------|
| D-01 | `docs/evidence/evidence-pipeline.md` line 146 | Uses `cosign blob-sign`; actual scripts correctly use `cosign sign-blob` |
| D-02 | `docs/evidence/evidence-pipeline.md` hash chain example | Doc signs the manifest file; actual script signs the chain entry (script approach is architecturally better) |
| D-03 | `docs/evidence/evidence-pipeline.md` line 614 | Alertmanager API v1 in doc; actual `verify-evidence.sh` uses v2 API |
| D-04 | `docs/security/security-assessment.md` | Not listed in `stack-bom.md` document index table, though referenced elsewhere as "Appendix C" |

These discrepancies are typical of a design document written before implementation and then refined during build. The actual scripts are more correct and robust than the doc examples.

---

## Summary of Findings

| # | Severity | Finding | Recommendation |
|---|----------|---------|---------------|
| F-01 | Medium | POL-02 – POL-10 missing standard structural elements (metadata, sections, review log) | Align structure to POL-01 template |
| F-02 | Low | Risk register matrix is 3×4, not 4×4 as specified | Clarify specification or add 4th likelihood level |
| F-03 | Low | Evidence pipeline `CHAIN_PREFIX` configurable in collector but hard-coded in verifier | Parameterise verifier or document constraint |
| F-04 | Low | Evidence pipeline doc uses outdated cosign subcommand and signing target | Update doc examples to match implemented scripts |
| F-05 | Info | `CLAUDE.md` repo structure section missing newer files (`controls/`, `scripts/`, `docs/generated/`, `Makefile`, `artifact-index.yaml`) | Update CLAUDE.md |
| F-06 | Info | POL-08 and POL-10 missing GDPR cross-references in compliance mapping | Add GDPR mapping where applicable |
| F-07 | Info | Security assessment not listed in stack-bom.md document index | Add entry to document index table |

**Overall assessment:** The repository is well-structured, internally consistent, and fit for purpose as a governance-as-code framework. The automated validation pipeline passes. The actual scripts and controls are robust; findings are primarily about documentation alignment (policies needing structural consistency with POL-01, and evidence pipeline docs needing updates to match the implemented scripts).
