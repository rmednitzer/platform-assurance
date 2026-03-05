#!/usr/bin/env bash
# verify-evidence.sh — daily integrity health check
# Run via cron at 01:00 UTC; alerts on any failure
# Prerequisites: mc, cosign, rekor-cli, curl
set -euo pipefail

EVIDENCE_BUCKET="${EVIDENCE_BUCKET:-evidence}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://alertmanager:9093}"
FAILURES=0

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

# 1. Verify hash chain continuity (last 7 days)
log "Checking hash chain continuity..."
PREV_HASH="GENESIS"
for i in $(seq 7 -1 1); do
  DATE=$(date -u -d "${i} days ago" +%Y-%m-%d)
  CHAIN_FILE="minio/${EVIDENCE_BUCKET}/chain/${DATE}-chain-hash.txt"
  MANIFEST_FILE="minio/${EVIDENCE_BUCKET}/chain/${DATE}-manifest.txt"

  if mc stat "${CHAIN_FILE}" > /dev/null 2>&1; then
    STORED_HASH=$(mc cat "${CHAIN_FILE}")
    MANIFEST_HASH=$(mc cat "${MANIFEST_FILE}" | sha256sum | cut -d' ' -f1)
    EXPECTED=$(echo "${DATE}|${MANIFEST_HASH}|prev:${PREV_HASH}" | sha256sum | cut -d' ' -f1)

    if [ "${STORED_HASH}" != "${EXPECTED}" ]; then
      log "FAIL: Hash chain broken at ${DATE}"
      FAILURES=$((FAILURES + 1))
    else
      log "OK: ${DATE} chain verified"
    fi
    PREV_HASH="${STORED_HASH}"
  fi
done

# 2. Verify cosign signatures on latest CI evidence (sample check)
log "Checking cosign signatures on recent CI evidence..."
LATEST=$(mc ls "minio/${EVIDENCE_BUCKET}/ci/" --recursive 2>/dev/null | grep "evidence-manifest.json" | tail -1 | awk '{print $NF}')
if [ -n "${LATEST}" ]; then
  TMP=$(mktemp)
  mc cat "minio/${EVIDENCE_BUCKET}/ci/${LATEST}" > "${TMP}"
  BUNDLE="${LATEST%.json}.bundle"
  mc cat "minio/${EVIDENCE_BUCKET}/ci/${BUNDLE}" > "${TMP}.bundle" 2>/dev/null || true

  if [ -f "${TMP}.bundle" ]; then
    cosign verify-blob --bundle "${TMP}.bundle" "${TMP}" > /dev/null 2>&1 \
      && log "OK: Latest CI evidence signature valid" \
      || { log "FAIL: Latest CI evidence signature invalid"; FAILURES=$((FAILURES + 1)); }
  fi
  rm -f "${TMP}" "${TMP}.bundle"
fi

# 3. Verify Object Lock is active on evidence buckets
log "Checking Object Lock status..."
for PREFIX in ci runtime governance incidents; do
  mc retention info "minio/${EVIDENCE_BUCKET}/${PREFIX}/" 2>/dev/null | grep -q "COMPLIANCE" \
    && log "OK: ${PREFIX}/ Object Lock COMPLIANCE active" \
    || { log "FAIL: ${PREFIX}/ Object Lock not in COMPLIANCE mode"; FAILURES=$((FAILURES + 1)); }
done

# 4. Check backup age (evidence store itself)
log "Checking evidence store backup age..."
# Placeholder: adapt to your backup tooling
# Expected: backup age < 24 hours
# restic snapshots --json | jq '.[0].time' | ...

# 5. Report
if [ "${FAILURES}" -gt 0 ]; then
  log "EVIDENCE INTEGRITY CHECK FAILED: ${FAILURES} issue(s)"

  # Alert via Alertmanager
  curl -s -X POST "${ALERTMANAGER_URL}/api/v2/alerts" \
    -H "Content-Type: application/json" \
    -d "[{
      \"labels\": {
        \"alertname\": \"EvidenceIntegrityFailure\",
        \"severity\": \"critical\",
        \"source\": \"verify-evidence\"
      },
      \"annotations\": {
        \"summary\": \"Evidence integrity check failed: ${FAILURES} issue(s)\",
        \"description\": \"Run verify-evidence.sh manually for details\"
      }
    }]" || log "WARNING: Could not send alert to Alertmanager"

  exit 1
else
  log "All evidence integrity checks passed"
  exit 0
fi
