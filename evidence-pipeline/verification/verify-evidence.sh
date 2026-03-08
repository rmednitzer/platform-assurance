#!/usr/bin/env bash
# verify-evidence.sh — daily integrity health check
# Run via cron at 01:00 UTC; alerts on any failure
# Prerequisites: mc, cosign, curl
set -euo pipefail

EVIDENCE_BUCKET="${EVIDENCE_BUCKET:-evidence}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://alertmanager:9093}"
WINDOW_DAYS="${WINDOW_DAYS:-7}"
COSIGN_CERT_IDENTITY_REGEXP="${COSIGN_CERT_IDENTITY_REGEXP:-https://gitlab\\.com/.+}"
COSIGN_CERT_OIDC_ISSUER="${COSIGN_CERT_OIDC_ISSUER:-https://gitlab.com}"
FAILURES=0

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
fail() { log "FAIL: $*"; FAILURES=$((FAILURES + 1)); }

verify_chain_window() {
  log "Checking hash chain continuity..."
  local oldest_date
  oldest_date=$(date -u -d "${WINDOW_DAYS} days ago" +%Y-%m-%d)
  local anchor_date
  anchor_date=$(date -u -d "${WINDOW_DAYS}+1 days ago" +%Y-%m-%d)
  local prev_hash="GENESIS"

  if mc stat "minio/${EVIDENCE_BUCKET}/chain/${anchor_date}-chain-hash.txt" >/dev/null 2>&1; then
    prev_hash=$(mc cat "minio/${EVIDENCE_BUCKET}/chain/${anchor_date}-chain-hash.txt")
  fi

  for i in $(seq "${WINDOW_DAYS}" -1 1); do
    local date
    date=$(date -u -d "${i} days ago" +%Y-%m-%d)
    local manifest_file="minio/${EVIDENCE_BUCKET}/chain/${date}-manifest.txt"
    local entry_file="minio/${EVIDENCE_BUCKET}/chain/${date}-chain-entry.txt"
    local hash_file="minio/${EVIDENCE_BUCKET}/chain/${date}-chain-hash.txt"
    local bundle_file="minio/${EVIDENCE_BUCKET}/chain/${date}-chain-entry.bundle"

    for required in "${manifest_file}" "${entry_file}" "${hash_file}" "${bundle_file}"; do
      if ! mc stat "${required}" >/dev/null 2>&1; then
        fail "Missing chain artifact ${required#minio/${EVIDENCE_BUCKET}/}"
        continue 2
      fi
    done

    local manifest_hash stored_hash expected_hash entry_text expected_entry
    manifest_hash=$(mc cat "${manifest_file}" | sha256sum | cut -d' ' -f1)
    stored_hash=$(mc cat "${hash_file}")
    expected_entry="${date}|${manifest_hash}|prev:${prev_hash}"
    entry_text=$(mc cat "${entry_file}" | tr -d '\n')
    expected_hash=$(printf '%s\n' "${expected_entry}" | sha256sum | cut -d' ' -f1)

    if [ "${entry_text}" != "${expected_entry}" ]; then
      fail "Chain entry mismatch at ${date}"
    fi
    if [ "${stored_hash}" != "${expected_hash}" ]; then
      fail "Hash chain broken at ${date}"
    else
      log "OK: ${date} chain verified"
    fi

    local tmp
    tmp=$(mktemp)
    mc cat "${entry_file}" > "${tmp}"
    mc cat "${bundle_file}" > "${tmp}.bundle"
    if cosign verify-blob \
      --bundle "${tmp}.bundle" \
      --certificate-identity-regexp "${COSIGN_CERT_IDENTITY_REGEXP}" \
      --certificate-oidc-issuer "${COSIGN_CERT_OIDC_ISSUER}" \
      "${tmp}" >/dev/null 2>&1; then
      log "OK: ${date} chain entry signature valid"
    else
      fail "Chain entry signature invalid at ${date}"
    fi
    rm -f "${tmp}" "${tmp}.bundle"
    prev_hash="${stored_hash}"
  done
}

verify_latest_ci_signature() {
  log "Checking cosign signatures on recent CI evidence..."
  local latest
  latest=$(mc ls "minio/${EVIDENCE_BUCKET}/ci/" --recursive 2>/dev/null | grep "evidence-manifest.json" | tail -1 | awk '{print $NF}')
  if [ -z "${latest}" ]; then
    fail "No CI evidence manifest found"
    return
  fi

  local tmp bundle_rel
  tmp=$(mktemp)
  mc cat "minio/${EVIDENCE_BUCKET}/ci/${latest}" > "${tmp}"
  bundle_rel="${latest%.json}.bundle"
  if ! mc stat "minio/${EVIDENCE_BUCKET}/ci/${bundle_rel}" >/dev/null 2>&1; then
    fail "Missing CI bundle ${bundle_rel}"
    rm -f "${tmp}"
    return
  fi
  mc cat "minio/${EVIDENCE_BUCKET}/ci/${bundle_rel}" > "${tmp}.bundle"

  if cosign verify-blob \
    --bundle "${tmp}.bundle" \
    --certificate-identity-regexp "${COSIGN_CERT_IDENTITY_REGEXP}" \
    --certificate-oidc-issuer "${COSIGN_CERT_OIDC_ISSUER}" \
    "${tmp}" >/dev/null 2>&1; then
    log "OK: Latest CI evidence signature valid"
  else
    fail "Latest CI evidence signature invalid"
  fi
  rm -f "${tmp}" "${tmp}.bundle"
}

verify_object_lock() {
  log "Checking Object Lock status..."
  for prefix in ci runtime governance incidents dr-tests; do
    if mc retention info "minio/${EVIDENCE_BUCKET}/${prefix}/" 2>/dev/null | grep -q "COMPLIANCE"; then
      log "OK: ${prefix}/ Object Lock COMPLIANCE active"
    else
      fail "${prefix}/ Object Lock not in COMPLIANCE mode"
    fi
  done
}

send_alert() {
  curl --fail --silent --show-error -X POST "${ALERTMANAGER_URL}/api/v2/alerts" \
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
    }]"
}

verify_chain_window
verify_latest_ci_signature
verify_object_lock
log "Checking evidence store backup age..."
# Placeholder: adapt to your backup tooling and fail if snapshot age exceeds policy.

if [ "${FAILURES}" -gt 0 ]; then
  log "EVIDENCE INTEGRITY CHECK FAILED: ${FAILURES} issue(s)"
  send_alert || log "WARNING: Could not send alert to Alertmanager"
  exit 1
fi

log "All evidence integrity checks passed"
exit 0
