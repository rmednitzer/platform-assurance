# Access Review: [QUARTER / DATE]

**Reviewer:** [Manager name]
**Scope:** [Team / System / Namespace]
**Date completed:** YYYY-MM-DD

## User access review

| User | Role(s) | Last active | Decision | Justification |
|------|---------|-------------|----------|---------------|
| [user@example.com] | [platform-operator] | [YYYY-MM-DD] | Retain / Revoke | [Business need] |
| | | | | |

## Service account review

| Service account | Purpose | Owner | Last used | Lease TTL | Decision | Justification |
|----------------|---------|-------|-----------|-----------|----------|---------------|
| [sa-ci-deploy] | CI/CD deployment | [Owner] | [YYYY-MM-DD] | [1h] | Retain / Revoke | |
| | | | | | | |

## Privileged access review

| User | Privilege | Justification | Time-limited? | Decision |
|------|-----------|---------------|---------------|----------|
| | cluster-admin | | Yes (JIT) / No | Retain / Revoke / Convert to JIT |
| | | | | |

## Findings and actions

| # | Finding | Action | Owner | Deadline |
|---|---------|--------|-------|----------|
| 1 | [Example: SA not used in 90 days] | Revoke | [Owner] | YYYY-MM-DD |

## Sign-off

| Role | Name | Date |
|------|------|------|
| Reviewing manager | | |
| CISO (if privileged access changes) | | |
