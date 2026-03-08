# Asset Inventory

**Owner:** Operations Lead
**Review cycle:** Continuous + annual validation
**Last validated:** YYYY-MM-DD

## Systems

| Asset ID | Name | Type | Owner | Classification | Data types | Environment | Backup | RTO/RPO | Notes |
|----------|------|------|-------|---------------|------------|-------------|--------|---------|-------|
| SYS-001 | [Example: PostgreSQL primary] | Database | [Owner] | Restricted | Personal data, financial | Prod | pgBackRest (hourly WAL, daily base) | 4h / 1h | |
| SYS-002 | [Example: Keycloak] | Identity provider | [Owner] | Restricted | Authentication credentials | Prod | Velero + DB backup | 4h / 1h | |
| SYS-003 | | | | | | | | | |

## Data flows

| Source | Destination | Data classification | Encryption | Cross-border? |
|--------|-------------|-------------------|------------|---------------|
| [Example: User browser] | Kong API gateway | Confidential | TLS 1.3 | No |
| | | | | |

## Review log

| Date | Reviewer | Changes |
|------|----------|---------|
| YYYY-MM-DD | [Name] | Initial creation |
