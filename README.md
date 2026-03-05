# Platform Assurance Repository

Infrastructure-as-code governance for an EU-regulated platform stack.

## Status

| Area | Status |
|------|--------|
| Stack BOM (§1–§17) | DRAFT — validated |
| License audit | Complete |
| Regulatory mapping (NIS2/CRA/GDPR) | Complete — verify against NISG 2026 after 2026-10-01 |
| Security assessment | Complete — verification sprint needed |
| Evidence pipeline | Designed — implementation phases P1–P8 |
| AI + API architecture | Designed — implementation phases P1–P10 |
| Observability + IAM | Designed |
| ISMS policies (10) | Template ready — legal review + board approval required |
| Supporting registers | Stub — initial population required |

## Repository structure

```
.
├── README.md                          # This file
├── CONTRIBUTING.md                    # Contribution and review process
├── .github/
│   └── CODEOWNERS                     # Review requirements per path
│
├── docs/                              # Architecture and analysis documents
│   ├── architecture/
│   │   ├── stack-bom.md               # Master BOM (§1–§17)
│   │   └── validation-report.md       # Cross-document QA
│   ├── security/
│   │   └── security-assessment.md     # STRIDE per trust boundary
│   ├── compliance/
│   │   ├── license-audit.md           # OSS/BSL/proprietary per component
│   │   ├── regulatory-mapping.md      # NIS2/CRA/GDPR → controls
│   │   └── isms-policies.md           # Policy set overview + cross-references
│   ├── evidence/
│   │   └── evidence-pipeline.md       # Generation, signing, storage architecture
│   ├── ai-api/
│   │   └── ai-api-management.md       # AI workloads + API gateway + LLM gateway
│   └── observability/
│       └── observability-iam.md       # Request-to-evidence flow + IAM
│
├── policies/                          # Approved ISMS policy documents
│   ├── POL-01-information-security.md
│   ├── POL-02-risk-management.md
│   ├── POL-03-access-control.md
│   ├── POL-04-incident-response.md
│   ├── POL-05-business-continuity.md
│   ├── POL-06-cryptography.md
│   ├── POL-07-supply-chain.md
│   ├── POL-08-secure-development.md
│   ├── POL-09-data-classification.md
│   └── POL-10-change-management.md
│
├── registers/                         # Living governance registers
│   ├── risk-register.md               # Risk register with treatment plan
│   ├── asset-inventory.md             # Systems, data, classification
│   ├── supplier-register.md           # Critical suppliers + assessment status
│   └── ropa.md                        # Records of processing activities (GDPR Art 30)
│
├── templates/                         # Reusable templates for recurring processes
│   ├── dpia/
│   │   └── TEMPLATE-dpia.md
│   ├── incident/
│   │   └── TEMPLATE-incident-report.md
│   ├── supplier/
│   │   └── TEMPLATE-supplier-assessment.md
│   ├── access-review/
│   │   └── TEMPLATE-access-review.md
│   └── dr-test/
│       └── TEMPLATE-dr-test-report.md
│
└── evidence-pipeline/                 # Evidence pipeline implementation
    ├── ci/
    │   └── evidence-stage.yml         # GitLab CI evidence generation stage
    ├── collectors/
    │   └── daily-hash-chain.sh        # Daily evidence integrity chain
    └── verification/
        └── verify-evidence.sh         # Automated integrity verification
```

## Conventions

- All documents use [F]/[I]/[S] epistemic tags with {50,70,80,90} confidence
- Dates: YYYY-MM-DD; Times: 24h; Units: SI; Currency: EUR
- Policies require signed Git tags on approval
- Registers are append-mostly; changes via merge request with review
- Evidence artifacts flow to MinIO WORM via the evidence pipeline

## Regulatory scope

- **NIS2 / NISG 2026** (AT, effective 2026-10-01)
- **CRA** (EU 2024/2847)
- **GDPR / DSG** (Austrian Datenschutzgesetz)
- **ISO/IEC 27001:2022** (ISMS)
- **SCF** (Secure Controls Framework)

## Getting started

1. Read `docs/architecture/stack-bom.md` — the master component inventory
2. Review `policies/` — adapt templates to your org; get legal review + board sign-off
3. Populate `registers/` — risk register, asset inventory, ROPA, supplier list
4. Implement evidence pipeline — start with `evidence-pipeline/ci/evidence-stage.yml`
