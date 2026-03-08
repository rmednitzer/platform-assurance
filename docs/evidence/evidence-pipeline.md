# Evidence Pipeline — Generation, Signing, and Centralised Storage

**Date:** 2026-03-05
**Scope:** End-to-end evidence lifecycle for NIS2 / CRA / GDPR audit readiness
**Status:** DRAFT — implementation design; review before build

---

## Design principle

Every auditable claim must trace to a signed, timestamped, immutable artifact stored in a location the claimant cannot retroactively modify. The pipeline has three stages: **generate → sign → store**. Each stage produces its own integrity signal.

---

## 1 — Architecture overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     EVIDENCE SOURCES                             │
│                                                                  │
│  GitLab CI ─── Build artifacts, SBOM, provenance, scan reports   │
│  Argo CD ───── Sync events, drift alerts, deployment manifests   │
│  Prometheus ── SLO reports, alert history, metric snapshots      │
│  Wazuh ─────── Security events, FIM alerts, SIEM correlation     │
│  Vault/OpenBao ── Audit logs, lease records, secret access trail    │
│  Kyverno ───── Admission decisions (allow/deny + policy version) │
│  Falco ─────── Runtime anomaly events                            │
│  K8s API ───── API audit log (RequestResponse)                   │
│  Backup tools ─ Restore test results, integrity checks           │
│  Manual ────── Board minutes, training records, risk register    │
│                                                                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                     EVIDENCE COLLECTOR                            │
│                                                                  │
│  Fluent Bit / Vector ── structured log forwarding                │
│  CI pipeline jobs ───── artifact generation + signing steps      │
│  Cron collectors ────── periodic evidence snapshots              │
│  Manual upload ──────── governance docs via CLI tool              │
│                                                                  │
│  At this stage: each artifact gets:                              │
│    1. SHA-256 hash                                               │
│    2. Timestamp (chrony-synced source)                           │
│    3. Source metadata (who/what/when/where)                      │
│                                                                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                     SIGNING LAYER                                │
│                                                                  │
│  cosign (Sigstore) ──── OCI artifacts (images, SBOM, provenance) │
│  cosign blob-sign ───── non-OCI evidence files                   │
│  Rekor ─────────────── transparency log entry per signature      │
│  GPG (fallback) ─────── manual/governance docs where cosign not  │
│                         applicable                               │
│                                                                  │
│  Signing identity:                                               │
│    - CI artifacts: keyless via GitLab OIDC → Fulcio cert         │
│    - Infrastructure evidence: service account key or keyless     │
│    - Governance docs: named human signer (GPG or cosign)         │
│                                                                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                     EVIDENCE STORE + CATALOGUE                   │
│                                                                  │
│  MinIO S3 ──────────── Object Lock (COMPLIANCE mode)             │
│    ├── /evidence/ci/{project}/{pipeline-id}/                     │
│    ├── /evidence/runtime/{date}/                                 │
│    ├── /evidence/governance/{year}/                              │
│    ├── /evidence/incidents/{incident-id}/                        │
│    ├── /evidence/dr-tests/{date}/                                │
│    └── /evidence/chain/                                          │
│    Underlying: ZFS pool (checksumming + scrub)                   │
│    Replica: ZFS send/receive to Site B (off-site DR)             │
│                                                                  │
│  OpenSearch ────────── Evidence catalogue (metadata index)        │
│    Index: evidence-artifacts-*                                   │
│    ILM: retention per tier (1y / 3y / 5y / 10y)                 │
│    Query: time-range, full-text, tag filter, aggregation         │
│    Dashboard: OpenSearch Dashboards / Grafana                    │
│                                                                  │
│  OCI Registry (Harbor) ── images + SBOM + attestations as OCI    │
│                           artifacts (referrers API)              │
│                                                                  │
│  Rekor log ─────────── tamper-evident signing transparency       │
│                                                                  │
│  Storage architecture:                                           │
│    Site A: MinIO (WORM) on ZFS → primary                         │
│    Site B: ZFS receive target → read-only replica                │
│    Rekor: independent timestamp verification                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2 — Evidence types and generation

### 2.1 — CI/CD pipeline evidence (per build/release)

Generated automatically in GitLab CI. Each release produces an **evidence bundle** as pipeline artifacts.

| Artifact | Tool | Format | Signing method |
|----------|------|--------|----------------|
| Container image | BuildKit / Podman | OCI image | cosign keyless (GitLab OIDC → Fulcio) |
| SBOM | Syft | CycloneDX JSON + SPDX JSON | cosign attach + sign (OCI artifact) |
| SLSA provenance | GitLab native or custom in-toto step | in-toto SLSA predicate v1.0 | cosign attest (DSSE envelope) |
| Vulnerability scan | Trivy | JSON report | cosign blob-sign |
| IaC scan | Trivy (IaC mode) | JSON report | cosign blob-sign |
| License compliance | ORT / Trivy license | JSON report | cosign blob-sign |
| Policy gate result | Kyverno CLI / conftest | JSON pass/fail per policy | cosign blob-sign |
| Rendered manifests | Helm template / Kustomize build | YAML (frozen) | SHA-256 in provenance |
| Evidence manifest | Custom script | JSON index of all above + hashes | cosign blob-sign |

**GitLab CI evidence stage (skeleton):**

```yaml
# .gitlab-ci.yml — evidence generation stage
evidence:
  stage: evidence
  image: registry.example.com/ci-tools:latest
  script:
    # 1. Generate SBOM
    - syft ${IMAGE} -o cyclonedx-json > sbom-cdx.json
    - syft ${IMAGE} -o spdx-json > sbom-spdx.json

    # 2. Scan for vulnerabilities
    - trivy image --format json --output vuln-report.json ${IMAGE}

    # 3. Sign image (keyless via GitLab OIDC)
    - cosign sign --yes ${IMAGE}

    # 4. Attach and sign SBOM as OCI artifact
    - cosign attach sbom --sbom sbom-cdx.json ${IMAGE}
    - cosign attest --yes --predicate sbom-cdx.json --type cyclonedx ${IMAGE}

    # 5. Generate SLSA provenance attestation
    - cosign attest --yes --predicate provenance.json --type slsaprovenance ${IMAGE}

    # 6. Sign non-OCI evidence files
    - cosign blob-sign --yes --bundle vuln-report.bundle vuln-report.json
    - cosign blob-sign --yes --bundle policy-result.bundle policy-result.json

    # 7. Build evidence manifest (index of all artifacts + hashes)
    - |
      cat > evidence-manifest.json <<EOF
      {
        "pipeline_id": "${CI_PIPELINE_ID}",
        "project": "${CI_PROJECT_PATH}",
        "commit": "${CI_COMMIT_SHA}",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "image_digest": "$(crane digest ${IMAGE})",
        "artifacts": {
          "sbom_cdx": "$(sha256sum sbom-cdx.json | cut -d' ' -f1)",
          "sbom_spdx": "$(sha256sum sbom-spdx.json | cut -d' ' -f1)",
          "vuln_report": "$(sha256sum vuln-report.json | cut -d' ' -f1)",
          "provenance": "$(sha256sum provenance.json | cut -d' ' -f1)"
        }
      }
      EOF
    - cosign blob-sign --yes --bundle manifest.bundle evidence-manifest.json

    # 8. Upload to evidence store (MinIO WORM bucket)
    - mc cp --recursive evidence/ minio/evidence/ci/${CI_PROJECT_PATH}/${CI_PIPELINE_ID}/

  artifacts:
    paths:
      - sbom-cdx.json
      - sbom-spdx.json
      - vuln-report.json
      - evidence-manifest.json
      - "*.bundle"
    expire_in: never
```

### 2.2 — Runtime evidence (continuous)

Collected by log shippers and periodic cron jobs. Not per-release — continuous evidence that controls are active.

| Artifact | Source | Collection method | Frequency | Signing |
|----------|--------|-------------------|-----------|---------|
| Kyverno admission decisions | Kyverno event log | Fluent Bit → MinIO | Continuous (stream) | Append-only bucket; daily hash chain |
| Falco runtime alerts | Falco gRPC output | Fluent Bit → MinIO | Continuous | Append-only bucket; daily hash chain |
| Wazuh security events | Wazuh manager | Wazuh archive → MinIO | Continuous | Wazuh-signed archive; daily hash chain |
| Vault/OpenBao audit log | Vault/OpenBao file/syslog audit device | Fluent Bit → MinIO | Continuous | Append-only; daily hash chain |
| K8s API audit log | API server audit webhook | Fluent Bit → MinIO | Continuous | Append-only; daily hash chain |
| Prometheus alert history | Alertmanager API | Cron (daily export) | Daily | cosign blob-sign |
| SELinux/AppArmor enforcement status | Ansible fact gather | Cron (weekly) | Weekly | cosign blob-sign |
| Kyverno policy snapshot | `kubectl get cpol -o yaml` | Cron (daily) | Daily | cosign blob-sign |
| Network policy snapshot | `kubectl get networkpolicy -A -o yaml` | Cron (daily) | Daily | cosign blob-sign |
| chrony sync status | `chronyc tracking` on all nodes | Cron (hourly) | Hourly | Append-only log |
| Backup integrity check | restic/borg verify + ZFS scrub | Post-backup hook | Per backup | cosign blob-sign |
| Restore test result | Manual/scripted DR test | Monthly | Monthly | Human signer (cosign or GPG) |

### 2.3 — Governance evidence (periodic / event-driven)

| Artifact | Owner | Frequency | Format | Signing |
|----------|-------|-----------|--------|---------|
| Risk register | CISO / security lead | Quarterly review | Markdown in Git | Signed Git tag |
| Board security approval minutes | Board secretary | Annual + event-driven | PDF | GPG or cosign blob-sign by named signer |
| Management training records | HR / security lead | Annual | CSV/PDF | cosign blob-sign |
| DPIA (per processing activity) | DPO | Event-driven | Markdown in Git | Signed Git tag |
| Supplier assessment records | Procurement / security | Annual per critical supplier | Markdown/PDF | cosign blob-sign |
| Incident reports (final) | Incident commander | Per incident | Markdown in Git | Signed Git tag |
| NIS2 notification confirmations | Legal / CISO | Per incident | PDF (authority receipt) | cosign blob-sign |
| ROPA | DPO | Quarterly review | Spreadsheet in Git | Signed Git tag |

---

## 3 — Signing architecture

### 3.1 — Signing methods by evidence type

| Context | Method | Identity | Key management |
|---------|--------|----------|----------------|
| CI/CD OCI artifacts | cosign keyless (Sigstore) | GitLab OIDC token → Fulcio short-lived cert | No key to manage; identity = pipeline path |
| CI/CD non-OCI files | cosign blob-sign keyless | GitLab OIDC token → Fulcio | Same as above |
| Infrastructure evidence | cosign with service account key OR keyless via workload identity | Service account or K8s SPIFFE identity | Key in Vault; rotated quarterly |
| Governance documents | GPG key of named human signer | Personal GPG key (verified via Web of Trust or org CA) | Key on hardware token (YubiKey); revocation published |
| Git-based artifacts | Signed Git tags/commits | Developer GPG/SSH key | Enforced by GitLab protected branch rules |

### 3.2 — Rekor transparency log

Every cosign operation (keyless or keyed) produces a Rekor entry. This provides:

- **Tamper evidence:** if a signature is later revoked or artifact modified, the original Rekor entry persists
- **Timestamping:** Rekor provides an independent timestamp (does not depend on your chrony)
- **Public auditability:** anyone can verify a signing event occurred (for public Rekor; use private instance for confidential evidence)

**Decision: public vs. private Rekor.**

| Factor | Public Rekor (sigstore.dev) | Private Rekor (self-hosted) |
|--------|---------------------------|----------------------------|
| Trust | Third-party operated (Sigstore community) | Self-operated |
| Visibility | Image digests + signing identities visible to anyone | Only visible to your org |
| Availability | Dependent on external service | Under your control |
| Audit credibility | Higher (independent third party) | Lower (self-attested) |

**Recommendation:** Use public Rekor for open-source or externally-published artifacts. Use private Rekor for internal evidence where image names or pipeline paths are confidential. Both can coexist. [I] {80}

### 3.3 — Daily hash chain (for continuous log streams)

For evidence that flows continuously (Kyverno, Falco, Vault audit, K8s API audit), individual signing per event is impractical. Instead, use a **daily hash chain**:

```bash
#!/bin/bash
# daily-hash-chain.sh — run at 00:05 UTC via cron
# Produces a signed daily digest of all evidence files written in the previous day

DATE=$(date -u -d "yesterday" +%Y-%m-%d)
EVIDENCE_DIR="evidence/runtime/${DATE}"

# 1. List all files written yesterday and compute SHA-256
mc find minio/${EVIDENCE_DIR} --newer-than "${DATE}T00:00:00Z" \
  | while read f; do mc cat "minio/$f" | sha256sum; done \
  | sort > /tmp/daily-manifest-${DATE}.txt

# 2. Compute digest of the manifest itself
MANIFEST_HASH=$(sha256sum /tmp/daily-manifest-${DATE}.txt | cut -d' ' -f1)

# 3. Chain to previous day's hash (append-only chain)
PREV_HASH=$(mc cat minio/evidence/chain/latest-hash.txt 2>/dev/null || echo "GENESIS")
CHAIN_ENTRY="${DATE}|${MANIFEST_HASH}|prev:${PREV_HASH}"
echo "${CHAIN_ENTRY}" | sha256sum | cut -d' ' -f1 > /tmp/chain-hash-${DATE}.txt

# 4. Sign the chain entry
cosign blob-sign --yes --bundle /tmp/chain-${DATE}.bundle /tmp/daily-manifest-${DATE}.txt

# 5. Upload manifest, chain hash, and signature to evidence store
mc cp /tmp/daily-manifest-${DATE}.txt minio/evidence/chain/${DATE}-manifest.txt
mc cp /tmp/chain-hash-${DATE}.txt minio/evidence/chain/${DATE}-chain-hash.txt
mc cp /tmp/chain-${DATE}.bundle minio/evidence/chain/${DATE}-manifest.bundle
mc cp /tmp/chain-hash-${DATE}.txt minio/evidence/chain/latest-hash.txt
```

**Verification:** To prove no evidence was tampered with, replay the hash chain from genesis. Each day's manifest must hash to the recorded value, and each chain entry must link to the previous day's hash. A break in the chain indicates tampering or data loss.

---

## 4 — Centralised evidence store

### 4.1 — MinIO with Object Lock (COMPLIANCE mode)

MinIO S3-compatible storage with Object Lock in COMPLIANCE mode provides **WORM** (Write Once Read Many) semantics — not even the MinIO admin can delete objects before the retention period expires.

```bash
# Create WORM bucket with default retention
mc mb minio/evidence --with-lock
mc retention set --default COMPLIANCE 365d minio/evidence/runtime/
mc retention set --default COMPLIANCE 1095d minio/evidence/ci/        # 3 years
mc retention set --default COMPLIANCE 3650d minio/evidence/governance/ # 10 years (CRA)
mc retention set --default COMPLIANCE 1825d minio/evidence/incidents/  # 5 years

# Verify lock is active
mc retention info minio/evidence/ci/
# Expected: Mode: COMPLIANCE, Validity: 1095 days
```

### 4.2 — Bucket structure

```
evidence/
├── ci/{project}/{pipeline-id}/
│   ├── sbom-cdx.json
│   ├── sbom-spdx.json
│   ├── vuln-report.json
│   ├── vuln-report.bundle          # cosign signature bundle
│   ├── provenance.json
│   ├── policy-result.json
│   ├── evidence-manifest.json
│   └── manifest.bundle
├── runtime/{date}/
│   ├── kyverno-decisions/
│   ├── falco-events/
│   ├── vault-audit/
│   ├── k8s-api-audit/
│   └── wazuh-archive/
├── governance/{year}/
│   ├── risk-register-{date}.md.sig
│   ├── board-minutes-{date}.pdf.sig
│   ├── training-records-{date}.csv.sig
│   ├── dpia-{name}-{date}.md.sig
│   ├── supplier-assessments/
│   └── ropa-{date}.csv.sig
├── incidents/{incident-id}/
│   ├── timeline.md
│   ├── notification-records/
│   ├── forensic-artifacts/
│   └── final-report.md.sig
├── dr-tests/{date}/
│   ├── restore-test-result.json
│   └── restore-test-result.bundle
└── chain/
    ├── {date}-manifest.txt
    ├── {date}-manifest.bundle
    ├── {date}-chain-hash.txt
    └── latest-hash.txt
```

### 4.3 — Access control

| Role | Read | Write | Delete | Use case |
|------|------|-------|--------|----------|
| CI pipeline service account | Own project prefix only | Own project prefix only | Never | Automated evidence upload |
| Evidence collector (runtime) | runtime/ prefix | runtime/ prefix | Never | Log shipping |
| CISO / security lead | All | governance/ + incidents/ | Never | Manual governance upload + audit review |
| DPO | governance/ + incidents/ (personal data subset) | governance/ (DPIA, ROPA) | Never | Privacy evidence |
| External auditor | Read-only (time-scoped temporary credentials) | Never | Never | Audit access |
| MinIO admin | Operational (bucket management) | Bucket policy only | **Cannot delete (COMPLIANCE lock)** | Infrastructure management |

---

## 5 — Evidence catalogue (OpenSearch)

MinIO stores the artifacts; OpenSearch makes them findable. The catalogue is an **index over the evidence store**, not a replacement for it.

### 5.1 — Why OpenSearch, not PostgreSQL

OpenSearch is already in the stack for logs and search. The evidence query patterns — time-range filters, full-text search on descriptions, tag-based faceting ("show me everything tagged NIS2"), aggregation dashboards ("how many SBOMs per project this quarter") — are exactly what OpenSearch is built for. ILM (Index Lifecycle Management) handles retention natively. OpenSearch Dashboards and Grafana provide the auditor-facing UI for free.

### 5.2 — Index template

```json
{
  "index_patterns": ["evidence-artifacts-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "index.lifecycle.name": "evidence-ilm",
      "index.lifecycle.rollover_alias": "evidence-artifacts"
    },
    "mappings": {
      "properties": {
        "artifact_id":       { "type": "keyword" },
        "artifact_type":     { "type": "keyword" },
        "source":            { "type": "keyword" },
        "project":           { "type": "keyword" },
        "service":           { "type": "keyword" },
        "pipeline_id":       { "type": "keyword" },
        "incident_id":       { "type": "keyword" },
        "created_at":        { "type": "date" },
        "sha256_hash":       { "type": "keyword" },
        "s3_bucket":         { "type": "keyword" },
        "s3_key":            { "type": "keyword" },
        "cosign_bundle_key": { "type": "keyword" },
        "rekor_log_index":   { "type": "long" },
        "rekor_uuid":        { "type": "keyword" },
        "signer_identity":   { "type": "keyword" },
        "signing_method":    { "type": "keyword" },
        "retention_tier":    { "type": "keyword" },
        "retention_until":   { "type": "date" },
        "framework_tags":    { "type": "keyword" },
        "claim_refs":        { "type": "keyword" },
        "description":       { "type": "text", "analyzer": "standard" },
        "verified":          { "type": "boolean" },
        "last_verified_at":  { "type": "date" }
      }
    }
  }
}
```

### 5.3 — ILM policy (retention per tier)

```json
{
  "policy": {
    "description": "Evidence retention lifecycle",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [
          { "rollover": { "min_index_age": "30d", "min_primary_shard_size": "10gb" } }
        ],
        "transitions": [
          { "state_name": "warm", "conditions": { "min_index_age": "90d" } }
        ]
      },
      {
        "name": "warm",
        "actions": [
          { "replica_count": { "number_of_replicas": 1 } },
          { "force_merge": { "max_num_segments": 1 } }
        ],
        "transitions": [
          { "state_name": "cold", "conditions": { "min_index_age": "365d" } }
        ]
      },
      {
        "name": "cold",
        "actions": [
          { "read_only": {} }
        ],
        "transitions": [
          { "state_name": "delete", "conditions": { "min_index_age": "3650d" } }
        ]
      },
      {
        "name": "delete",
        "actions": [
          { "delete": {} }
        ]
      }
    ],
    "ism_template": [
      { "index_patterns": ["evidence-artifacts-*"], "priority": 100 }
    ]
  }
}
```

Note: the ILM delete age (3650d = 10 years) is the maximum tier. Individual documents carry `retention_tier` and `retention_until` fields. The ILM policy handles the index lifecycle; per-document retention is enforced by MinIO Object Lock on the artifact side. The catalogue entry outlives the artifact only in the "cold/read-only" state as a tombstone record proving the artifact existed. [I] {80}

### 5.4 — Indexing workflow

Every evidence upload (CI, runtime collector, manual) writes two things:

1. **Artifact → MinIO** (signed blob)
2. **Metadata → OpenSearch** (catalogue entry)

```bash
# Example: CI pipeline evidence upload + catalogue entry
# (runs in evidence stage of GitLab CI)

# Upload artifact to MinIO
mc cp vuln-report.json minio/evidence/ci/${PROJECT}/${PIPELINE_ID}/

# Index metadata in OpenSearch
HASH=$(sha256sum vuln-report.json | cut -d' ' -f1)
curl -X POST "https://opensearch.internal:9200/evidence-artifacts/_doc" \
  -H "Content-Type: application/json" \
  -d "{
    \"artifact_id\": \"$(uuidgen)\",
    \"artifact_type\": \"vuln_scan\",
    \"source\": \"gitlab-ci\",
    \"project\": \"${CI_PROJECT_PATH}\",
    \"service\": \"${SERVICE_NAME}\",
    \"pipeline_id\": \"${CI_PIPELINE_ID}\",
    \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
    \"sha256_hash\": \"${HASH}\",
    \"s3_bucket\": \"evidence\",
    \"s3_key\": \"ci/${CI_PROJECT_PATH}/${CI_PIPELINE_ID}/vuln-report.json\",
    \"cosign_bundle_key\": \"ci/${CI_PROJECT_PATH}/${CI_PIPELINE_ID}/vuln-report.bundle\",
    \"rekor_log_index\": ${REKOR_INDEX},
    \"signer_identity\": \"${CI_PROJECT_PATH}/.gitlab-ci.yml@${CI_COMMIT_REF_NAME}\",
    \"signing_method\": \"cosign-keyless\",
    \"retention_tier\": \"ci_3y\",
    \"retention_until\": \"$(date -u -d '+3 years' +%Y-%m-%dT%H:%M:%SZ)\",
    \"framework_tags\": [\"NIS2\", \"CRA\"],
    \"claim_refs\": [],
    \"description\": \"Trivy vulnerability scan for ${CI_PROJECT_PATH} pipeline ${CI_PIPELINE_ID}\",
    \"verified\": true,
    \"last_verified_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }"
```

### 5.5 — Auditor queries (examples)

```bash
# All SBOMs for a specific service in Q1 2026
GET /evidence-artifacts/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "artifact_type": "sbom" } },
        { "term": { "service": "payment-service" } },
        { "range": { "created_at": { "gte": "2026-01-01", "lt": "2026-04-01" } } }
      ]
    }
  }
}

# All evidence tagged NIS2 for incident IR-2026-003
GET /evidence-artifacts/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "framework_tags": "NIS2" } },
        { "term": { "incident_id": "IR-2026-003" } }
      ]
    }
  }
}

# Evidence coverage dashboard: count of artifacts per type per month
GET /evidence-artifacts/_search
{
  "size": 0,
  "aggs": {
    "by_month": {
      "date_histogram": { "field": "created_at", "calendar_interval": "month" },
      "aggs": {
        "by_type": { "terms": { "field": "artifact_type" } }
      }
    }
  }
}

# Unverified artifacts (integrity check failed or never ran)
GET /evidence-artifacts/_search
{
  "query": {
    "bool": {
      "should": [
        { "term": { "verified": false } },
        { "range": { "last_verified_at": { "lt": "now-7d" } } }
      ]
    }
  }
}
```

### 5.6 — Integrity guarantee layers

| Layer | What it proves | Survives |
|-------|---------------|----------|
| MinIO Object Lock (COMPLIANCE) | Artifact not modified or deleted before retention expiry | Admin compromise (cannot override COMPLIANCE mode) |
| SHA-256 hash in OpenSearch | Artifact content matches what was uploaded | Catalogue tampering detectable (hash mismatch on verification) |
| cosign signature + bundle | Artifact was signed by the claimed identity at the claimed time | Key compromise detectable (Rekor provides independent record) |
| Rekor transparency log | Signing event occurred (independent of your infrastructure) | Complete infrastructure loss (Rekor is external) |
| Daily hash chain | Set of artifacts for each day is complete and unmodified | Individual artifact deletion (chain breaks) |
| OpenSearch catalogue | Artifacts are findable, queryable, and framework-tagged | Catalogue loss (reconstructable from MinIO + Rekor) |

**If OpenSearch is lost:** Evidence artifacts survive in MinIO. Rekor entries prove signatures. The catalogue can be rebuilt by scanning MinIO objects and re-indexing metadata from the evidence manifests stored alongside each artifact. This is why the evidence manifest (evidence-manifest.json per pipeline) exists — it's the reconstruction source. [I] {85}

---

## 6 — Verification and audit workflow

### 6.1 — Automated verification (daily cron)

```bash
#!/bin/bash
# verify-evidence-integrity.sh — daily health check

FAILURES=0

# 1. Verify hash chain continuity
for date_file in $(mc ls minio/evidence/chain/ | grep chain-hash | sort); do
  # Recompute expected chain hash from manifest + previous hash
  # Compare to stored chain hash
  # Alert on mismatch
done

# 2. Verify cosign signatures on latest CI evidence
LATEST_PIPELINE=$(mc ls minio/evidence/ci/${PROJECT}/ | tail -1 | awk '{print $NF}')
cosign verify-blob \
  --bundle minio/evidence/ci/${PROJECT}/${LATEST_PIPELINE}/manifest.bundle \
  --certificate-identity-regexp "https://gitlab.example.com/${PROJECT}" \
  --certificate-oidc-issuer "https://gitlab.example.com" \
  minio/evidence/ci/${PROJECT}/${LATEST_PIPELINE}/evidence-manifest.json \
  || FAILURES=$((FAILURES+1))

# 3. Verify Rekor entries exist for latest signatures
rekor-cli search --email "${CI_SERVICE_ACCOUNT}" --artifact evidence-manifest.json \
  || FAILURES=$((FAILURES+1))

# 4. Verify Object Lock is still active on all evidence buckets
mc retention info minio/evidence/ci/ | grep -q "COMPLIANCE" || FAILURES=$((FAILURES+1))
mc retention info minio/evidence/runtime/ | grep -q "COMPLIANCE" || FAILURES=$((FAILURES+1))

# 5. Alert on failures
if [ $FAILURES -gt 0 ]; then
  echo "EVIDENCE INTEGRITY CHECK FAILED: ${FAILURES} issues" | \
    curl -X POST "${ALERTMANAGER_URL}/api/v1/alerts" -d "..."
fi
```

### 6.2 — Auditor access workflow

```
Auditor requests evidence for claim X
  │
  ├─ 1. Identify evidence artifacts supporting claim X
  │     (from evidence manifest or assurance case GSN node)
  │
  ├─ 2. Generate time-scoped read-only MinIO credentials
  │     mc admin user stsinfo ... --policy auditor-read-only --duration 72h
  │
  ├─ 3. Auditor downloads artifacts + cosign bundles
  │
  ├─ 4. Auditor verifies signatures independently
  │     cosign verify-blob --bundle <bundle> <artifact>
  │     rekor-cli verify --artifact <artifact>  # cross-check Rekor
  │
  └─ 5. Auditor confirms: artifact is authentic, timestamped,
        and was present in the evidence store during the audit period
```

---

## 7 — Implementation roadmap

| Phase | Scope | Effort | Dependencies |
|-------|-------|--------|--------------|
| **P1** | MinIO with Object Lock; bucket structure; retention policies; access control | S–M | MinIO deployed (already in BOM as S3-compatible storage) |
| **P2** | CI evidence stage in GitLab CI: SBOM + scan + sign + upload | M | cosign available in CI; GitLab OIDC configured for Sigstore |
| **P3** | Runtime evidence collection: Fluent Bit → MinIO for Kyverno/Falco/Vault/K8s audit | M | Fluent Bit output plugin for S3; output routing rules |
| **P4** | Daily hash chain cron + automated integrity verification | S | P1 + P2 complete |
| **P5** | Governance evidence upload CLI tool + GPG signing workflow | S | GPG keys on hardware tokens |
| **P6** | Private Rekor instance (if confidentiality required) | M | Decision: public vs. private Rekor |
| **P7** | Auditor access workflow + documentation | S | P1 complete |
| **P8** | Evidence-to-assurance-case linkage (GSN nodes → evidence pointers) | M | assurance-case-builder skill |

**Total estimated effort:** 4–6 weeks for a single engineer, phased. P1–P3 deliver the core pipeline; P4–P8 add integrity verification and audit tooling.

---

## 8 — What this does NOT cover

- **GRC tool / compliance platform:** This design uses MinIO + Git + CLI tooling. If the org scales to many frameworks and many auditors, a GRC platform (Vanta, Drata, or open-source equivalents) may be warranted to provide a unified dashboard. The evidence store design is compatible — a GRC tool would query MinIO via S3 API. [I] {70}
- **Legal hold:** If litigation or investigation requires evidence preservation beyond normal retention, Object Lock retention can be extended per-object but not shortened in COMPLIANCE mode. Establish a legal hold procedure. [S] {70}
- **Cross-DC replication of evidence store:** MinIO supports bucket replication. If your DR strategy requires evidence availability across sites, add replication with integrity verification on the replica. [I] {80}

---

*All tool references match the Stack BOM. No new dependencies except private Rekor (optional). Implementation uses cosign [S,75] — verify current cosign CLI syntax against upstream documentation before implementing.*
