# DR Test Report: [DATE]

**Test type:** Monthly restore / Quarterly DR scenario / Annual full exercise
**Service tested:** [Name]
**Service tier:** Critical / Important / Standard
**Test lead:** [Name]

## Test parameters

- **Backup source:** [restic/borg/Velero/pgBackRest/ZFS]
- **Backup age at test time:** [X hours/days]
- **Restore target:** [Isolated test environment — never production]
- **Expected RTO:** [per POL-05]
- **Expected RPO:** [per POL-05]

## Results

| Metric | Target | Actual | Pass? |
|--------|--------|--------|-------|
| Time to restore (RTO) | [X hours] | [Y hours] | Yes / No |
| Data loss (RPO) | [X hours] | [Y hours] | Yes / No |
| Data integrity verified | Checksum match | [Match / Mismatch] | Yes / No |
| Application health post-restore | Service responds correctly | [Result] | Yes / No |

## Verification steps performed

1. [Restore initiated: timestamp]
2. [Data integrity check: method + result]
3. [Application smoke test: method + result]
4. [Comparison to production: method + result]

## Issues found

| # | Issue | Impact | Remediation | Owner | Deadline |
|---|-------|--------|-------------|-------|----------|
| 1 | | | | | |

## Evidence

| Artifact | Location | Hash |
|----------|----------|------|
| Restore log | `evidence/dr-tests/[date]/` | sha256:... |
| Integrity check output | `evidence/dr-tests/[date]/` | sha256:... |

## Sign-off

| Role | Name | Date |
|------|------|------|
| Test lead | | |
| Operations lead | | |
