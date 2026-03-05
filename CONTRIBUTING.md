# Contributing

## Review process

All changes to this repository follow the change management policy (POL-10).

| Path | Review required | Approver |
|------|----------------|----------|
| `policies/` | Legal review + CISO + Board approval | CISO signs tag |
| `registers/` | CISO or register owner | Merge request review |
| `docs/` | Peer review (1 reviewer minimum) | Any team member |
| `templates/` | CISO review | Merge request review |
| `evidence-pipeline/` | Peer review + CISO | Treat as production change |

## Commit conventions

- Sign all commits (GPG or SSH): `git commit -S`
- Use conventional commits: `feat:`, `fix:`, `docs:`, `policy:`, `register:`
- Policy approvals: create a signed tag `policy/POL-XX-vN.N` after board sign-off

## Branch model

- `main` — approved, current state of governance
- `draft/*` — work in progress (policies under legal review, register updates)
- No direct pushes to `main` — merge requests only

## Evidence

Every approved policy version and register update is automatically uploaded to the evidence store (MinIO WORM) via CI pipeline. Do not manually upload — the pipeline handles signing and cataloguing.
