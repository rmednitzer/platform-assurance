# POL-05: Business Continuity and Disaster Recovery Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + Operations Lead
**Review cycle:** Annual

## RTO/RPO targets

| Service tier | RTO | RPO | Example services |
|-------------|-----|-----|-----------------|
| Critical | 4 hours | 1 hour | Authentication (Keycloak), primary DB (PostgreSQL) |
| Important | 24 hours | 4 hours | CI/CD pipeline, monitoring |
| Standard | 72 hours | 24 hours | Development tools, documentation |

## Backup strategy

- 3-2-1 rule: 3 copies, 2 different media, 1 off-site
- Encryption: all backups encrypted at rest (restic/borg)
- Immutability: at least one backup target is immutable (MinIO WORM or ZFS snapshot on air-gapped replica)
- Tools: restic/borg (general), pgBackRest (PostgreSQL), Velero (Kubernetes), ZFS send/receive

## Testing

- Monthly: restore test of one critical service (rotating); template: `templates/dr-test/`
- Quarterly: full DR scenario exercise
- Evidence: restore test log (time, data verification, RTO measured) → `evidence/dr-tests/`

## Activation criteria

- Criteria for declaring a disaster: [define per org]
- Escalation chain: [who declares, who authorises failover]
- Communication plan: internal, external, regulatory (parallel to POL-04 if incident-triggered)

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(c) | NIS2 Directive |
| ISO 27001:2022 A.5.29, A.5.30, A.8.13, A.8.14 | ISO 27001 |
| SCF BCD-01 | Secure Controls Framework |
| CRA Annex I Part I (DoS resilience) | CRA |
| GDPR Art 32(1)(b) | GDPR |
