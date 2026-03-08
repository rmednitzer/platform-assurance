# POL-06: Cryptography and Key Management Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Review cycle:** Annual

## Approved algorithms

- Symmetric: AES-256 (GCM or CBC with HMAC)
- Asymmetric: RSA ≥3072-bit; ECDSA P-256/P-384; Ed25519
- Hashing: SHA-256, SHA-384, SHA-512 (no MD5, no SHA-1)
- TLS: 1.2 minimum; 1.3 preferred; weak ciphers disabled

## Key management

- Generation: cryptographically secure RNG only
- Storage: Vault/OpenBao; hardware tokens (YubiKey) for human keys
- Rotation: TLS certificates via cert-manager (automated); Vault dynamic secrets (lease-based)
- Destruction: crypto-erase + documented destruction record

## Data at rest

- Database: PostgreSQL TDE or application-layer encryption via Vault Transit
- Storage: ZFS native encryption or LUKS on volumes with sensitive data
- Backups: restic/borg encryption (default)
- Evidence store: MinIO server-side encryption

## Data in transit

- External: TLS 1.2+ at Ingress
- East-west: Cilium mTLS or Istio/Linkerd mTLS
- Replication: encrypted ZFS send; TLS for Ceph

## Signing

- Code: GPG/SSH signed commits (enforced by GitLab)
- Artifacts: cosign (Sigstore keyless in CI; key-based as fallback)
- Evidence: cosign blob-sign; GPG for governance docs

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(h) | NIS2 Directive |
| ISO 27001:2022 A.8.24 | ISO 27001 |
| SCF CRY-01 | Secure Controls Framework |
| GDPR Art 32(1)(a) | GDPR |
| CRA Annex I Part I | CRA |
