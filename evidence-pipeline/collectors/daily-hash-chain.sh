#!/usr/bin/env bash
# daily-hash-chain.sh — run at 00:05 UTC via cron
# Produces a signed daily digest of evidence files written on the previous UTC day.
# Prerequisites: mc (MinIO client), cosign, sha256sum, python3
set -euo pipefail

DATE="${DATE_OVERRIDE:-$(date -u -d "yesterday" +%Y-%m-%d)}"
YEAR="${DATE%%-*}"
EVIDENCE_BUCKET="${EVIDENCE_BUCKET:-evidence}"
CHAIN_PREFIX="${CHAIN_PREFIX:-chain}"
EVIDENCE_PREFIXES="${EVIDENCE_PREFIXES:-ci runtime governance incidents dr-tests}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

object_written_on_date() {
  local object_path="$1"
  local target_date="$2"
  mc stat --json "${object_path}" 2>/dev/null | python3 - "$target_date" <<'PY'
import json
import sys

target = sys.argv[1]
obj = json.load(sys.stdin)
last_modified = (obj.get("lastModified") or obj.get("last_modified") or "")[:10]
print("yes" if last_modified == target else "no")
PY
}

hash_object() {
  local object_path="$1"
  mc cat "${object_path}" | sha256sum | awk -v p="${object_path#minio/}" '{print $1, p}'
}

collect_date_partition() {
  local alias_path="$1"
  if mc stat "${alias_path}" >/dev/null 2>&1; then
    mc find "${alias_path}" 2>/dev/null | while read -r rel; do
      [ -n "${rel}" ] || continue
      hash_object "minio/${rel}"
    done
  fi
}

collect_by_mtime() {
  local alias_path="$1"
  if mc stat "${alias_path}" >/dev/null 2>&1; then
    mc find "${alias_path}" 2>/dev/null | while read -r rel; do
      [ -n "${rel}" ] || continue
      local object_path="minio/${rel}"
      if [ "$(object_written_on_date "${object_path}" "${DATE}")" = "yes" ]; then
        hash_object "${object_path}"
      fi
    done
  fi
}

log "Starting hash chain for ${DATE}"
: > "${TMP_DIR}/daily-manifest-${DATE}.txt"

for prefix in ${EVIDENCE_PREFIXES}; do
  case "${prefix}" in
    runtime|dr-tests)
      collect_date_partition "minio/${EVIDENCE_BUCKET}/${prefix}/${DATE}" >> "${TMP_DIR}/daily-manifest-${DATE}.txt"
      ;;
    governance)
      collect_by_mtime "minio/${EVIDENCE_BUCKET}/${prefix}/${YEAR}" >> "${TMP_DIR}/daily-manifest-${DATE}.txt"
      ;;
    ci|incidents)
      collect_by_mtime "minio/${EVIDENCE_BUCKET}/${prefix}" >> "${TMP_DIR}/daily-manifest-${DATE}.txt"
      ;;
    *)
      log "WARNING: Unknown evidence prefix '${prefix}', skipping"
      ;;
  esac
done

sort -u -o "${TMP_DIR}/daily-manifest-${DATE}.txt" "${TMP_DIR}/daily-manifest-${DATE}.txt"
FILE_COUNT=$(wc -l < "${TMP_DIR}/daily-manifest-${DATE}.txt")
log "Found ${FILE_COUNT} evidence files for ${DATE}"

MANIFEST_HASH=$(sha256sum "${TMP_DIR}/daily-manifest-${DATE}.txt" | cut -d' ' -f1)
PREV_HASH=$(mc cat "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/latest-hash.txt" 2>/dev/null || echo "GENESIS")
printf '%s|%s|prev:%s\n' "${DATE}" "${MANIFEST_HASH}" "${PREV_HASH}" > "${TMP_DIR}/chain-entry-${DATE}.txt"
CHAIN_HASH=$(sha256sum "${TMP_DIR}/chain-entry-${DATE}.txt" | cut -d' ' -f1)
printf '%s\n' "${CHAIN_HASH}" > "${TMP_DIR}/chain-hash-${DATE}.txt"

cosign sign-blob --yes \
  --bundle "${TMP_DIR}/chain-entry-${DATE}.bundle" \
  "${TMP_DIR}/chain-entry-${DATE}.txt" >/dev/null

mc cp "${TMP_DIR}/daily-manifest-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-manifest.txt"
mc cp "${TMP_DIR}/chain-entry-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-chain-entry.txt"
mc cp "${TMP_DIR}/chain-hash-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-chain-hash.txt"
mc cp "${TMP_DIR}/chain-entry-${DATE}.bundle" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-chain-entry.bundle"
mc cp "${TMP_DIR}/chain-hash-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/latest-hash.txt"

log "Hash chain complete for ${DATE}: manifest=${MANIFEST_HASH}, chain_hash=${CHAIN_HASH}, prev=${PREV_HASH}"
