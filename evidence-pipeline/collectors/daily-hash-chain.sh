#!/usr/bin/env bash
# daily-hash-chain.sh — run at 00:05 UTC via cron
# Produces a signed daily digest of all evidence files written in the previous day
# Prerequisites: mc (MinIO client), cosign, sha256sum
set -euo pipefail

DATE=$(date -u -d "yesterday" +%Y-%m-%d)
EVIDENCE_BUCKET="${EVIDENCE_BUCKET:-evidence}"
CHAIN_PREFIX="chain"
TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting hash chain for ${DATE}"

# 1. List all files written yesterday and compute SHA-256
mc find "minio/${EVIDENCE_BUCKET}/runtime/${DATE}" 2>/dev/null | while read -r f; do
  mc cat "minio/${f}" | sha256sum | awk "{print \$1, \"${f}\"}"
done | sort > "${TMP_DIR}/daily-manifest-${DATE}.txt"

FILE_COUNT=$(wc -l < "${TMP_DIR}/daily-manifest-${DATE}.txt")
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Found ${FILE_COUNT} evidence files for ${DATE}"

# 2. Compute digest of the manifest itself
MANIFEST_HASH=$(sha256sum "${TMP_DIR}/daily-manifest-${DATE}.txt" | cut -d' ' -f1)

# 3. Chain to previous day's hash (append-only chain)
PREV_HASH=$(mc cat "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/latest-hash.txt" 2>/dev/null || echo "GENESIS")
CHAIN_ENTRY="${DATE}|${MANIFEST_HASH}|prev:${PREV_HASH}"
echo "${CHAIN_ENTRY}" | sha256sum | cut -d' ' -f1 > "${TMP_DIR}/chain-hash-${DATE}.txt"

# 4. Sign the chain entry
cosign blob-sign --yes \
  --bundle "${TMP_DIR}/chain-${DATE}.bundle" \
  "${TMP_DIR}/daily-manifest-${DATE}.txt"

# 5. Upload manifest, chain hash, and signature to evidence store
mc cp "${TMP_DIR}/daily-manifest-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-manifest.txt"
mc cp "${TMP_DIR}/chain-hash-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-chain-hash.txt"
mc cp "${TMP_DIR}/chain-${DATE}.bundle" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/${DATE}-manifest.bundle"
mc cp "${TMP_DIR}/chain-hash-${DATE}.txt" "minio/${EVIDENCE_BUCKET}/${CHAIN_PREFIX}/latest-hash.txt"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Hash chain complete for ${DATE}: manifest=${MANIFEST_HASH}, chain=${CHAIN_ENTRY}"
