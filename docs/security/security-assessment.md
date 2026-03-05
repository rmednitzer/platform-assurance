# Stack BOM — Security Control Sufficiency Assessment (Appendix C)

**Date:** 2026-03-05
**Method:** STRIDE per trust boundary, mapped to NIS2 Art 21 / CRA Annex I / GDPR Art 32 requirements.
**Status:** DRAFT — assessment is against the BOM inventory; actual sufficiency depends on implementation, configuration, and verification.

---

## Critical distinction: tool ≠ control ≠ evidence

| Layer | Question | Example |
|-------|----------|---------|
| **Tool present** | Is it in the stack? | "We have Falco" |
| **Control enforced** | Is it configured, in enforcing mode, and covering the right scope? | "Falco rules detect container escape, privilege escalation, and unexpected network connections in all prod namespaces" |
| **Evidence captured** | Can you prove to an auditor that the control was active and effective during the audit period? | "Falco alerts → Wazuh → WORM evidence store; monthly review records; no unresolved critical findings" |

The BOM gets you to "tool present." This assessment identifies where the gap is at the **control enforced** or **evidence captured** layer. [I] {85}

---

## 1 — Trust boundaries and STRIDE analysis

### TB1: External → Ingress (internet-facing edge)

| Threat | Stack component | Control status | Gap / risk |
|--------|----------------|----------------|------------|
| **Spoofing** (forged client identity) | Keycloak OIDC/MFA, Ingress TLS termination | ✅ Tool present | Verify: MFA enforced for all user-facing services, not just admin. Session fixation protections in Keycloak config. |
| **Tampering** (request manipulation) | TLS at Ingress (NGINX/HAProxy/Traefik), cert-manager for automated cert rotation | ✅ Tool present | Verify: TLS 1.2+ enforced, weak ciphers disabled, HSTS headers set. WAF/rate limiting may be absent — **gap if internet-facing services exist**. [S,70] |
| **Repudiation** (deny having performed action) | auditd, journald, OTel, Wazuh | ✅ Tool present | Verify: access logs are immutable/append-only, forwarded off-host, time-synced via chrony. |
| **Information disclosure** (data leak via edge) | TLS, Ingress config, network policy | ✅ Tool present | Verify: no plaintext endpoints exposed; error pages don't leak stack traces; CORS policy restrictive. |
| **DoS** (service disruption) | Cilium rate limiting, Ingress rate limiting | ⚠️ Partial | **Gap: no dedicated DDoS mitigation or WAF in the BOM.** For internet-facing services, consider cloud DDoS protection or ModSecurity/Coraza WAF. NIS2 Art 21.2(e) and CRA Annex I Part I both require DoS resilience. |
| **Elevation of privilege** (bypass to internal) | Ingress → backend network policy (Cilium), admission control (Kyverno) | ✅ Tool present | Verify: default-deny network policy enforced; Ingress controller runs with minimal privileges; no wildcard routes. |

### TB2: Cluster internal (pod-to-pod, east-west)

| Threat | Stack component | Control status | Gap / risk |
|--------|----------------|----------------|------------|
| **Spoofing** (pod impersonation) | Cilium identity, Istio/Linkerd mTLS (if deployed) | ⚠️ Conditional | mTLS is marked T0* conditional on NIS2/DORA. **If mTLS is not deployed, east-west traffic is unauthenticated.** Cilium mutual auth (without full mesh) is an alternative. Verify which is in place. |
| **Tampering** (in-cluster man-in-the-middle) | mTLS if deployed; otherwise plaintext | ⚠️ Conditional | Same dependency as spoofing. Without mTLS, in-cluster traffic is tamper-vulnerable on shared networks. |
| **Repudiation** | OTel tracing, Cilium flow logs, auditd | ✅ Tool present | Verify: Cilium Hubble/flow logs enabled and forwarded; OTel trace context propagated across services. |
| **Information disclosure** (secrets in etcd, env vars) | Vault/OpenBao dynamic secrets, ESO/Secrets Store CSI, SOPS+age | ✅ Tool present | Verify: etcd encryption at rest enabled; secrets not in environment variables (prefer volume mounts); Vault lease TTLs are short. |
| **DoS** (noisy neighbour, resource exhaustion) | K8s resource limits/requests, Pod Priority, LimitRanges | ⚠️ Partial | **Gap: resource limits are not in the BOM as an explicit control.** Must be enforced via Kyverno policy requiring resource limits on all pods. Without this, a single workload can starve the node. |
| **Elevation of privilege** (container escape, RBAC abuse) | Pod Security Admission/Standards, seccomp, SELinux/AppArmor, Falco, RBAC | ✅ Tool present | Verify: PSA enforced at `restricted` baseline in prod namespaces; no privileged containers; RBAC uses least-privilege (no cluster-admin for workloads); Falco rules detect privilege escalation. |

### TB3: CI/CD pipeline → production

| Threat | Stack component | Control status | Gap / risk |
|--------|----------------|----------------|------------|
| **Spoofing** (compromised runner, forged artifact) | Signed commits (GPG/SSH), cosign artifact signing, SLSA provenance, in-toto attestations | ✅ Tool present | Verify: signing is enforced (not optional); Kyverno admission policy rejects unsigned images; runners are ephemeral. |
| **Tampering** (build poisoning, dependency confusion) | Pinned dependencies, Trivy scanning, SBOM generation, hermetic-ish CI | ✅ Tool present | Verify: lock files committed; Trivy runs pre-merge (not just post-build); registry allow-list enforced at admission. **Gap: dependency confusion protection (namespace squatting) is not explicitly addressed.** [S,70] |
| **Repudiation** (who approved this deploy?) | GitLab protected branches, merge approval rules, Argo CD sync logs | ✅ Tool present | Verify: ≥2 approvals for prod merges; Argo CD sync events forwarded to audit log; no manual `kubectl apply` in prod. |
| **Information disclosure** (secrets in CI logs/artifacts) | SOPS+age, Vault, GitLab masked variables | ✅ Tool present | Verify: secret scanning in pipeline (no Gitleaks/truffleHog in BOM — **gap**); CI logs reviewed for accidental secret exposure. |
| **Elevation of privilege** (pipeline escape to prod cluster) | Argo CD RBAC, GitOps model (no direct push), Kyverno admission | ✅ Tool present | Verify: Argo CD service account has minimal RBAC; no shared credentials between CI and prod cluster admin. |

### TB4: Admin/operator → infrastructure

| Threat | Stack component | Control status | Gap / risk |
|--------|----------------|----------------|------------|
| **Spoofing** (compromised admin credential) | Keycloak MFA, SSH key auth, Vault dynamic credentials | ✅ Tool present | Verify: MFA on all admin paths (not just web UI); break-glass procedure documented; privileged access time-limited (Vault leases). |
| **Tampering** (config drift, unauthorized changes) | GitOps (Argo CD/Flux drift detection), Ansible idempotency, Terraform state | ✅ Tool present | Verify: Argo CD auto-sync with drift alerting; no manual changes permitted in prod; Terraform state locked and encrypted. |
| **Repudiation** | auditd, journald, K8s API audit log, Vault audit log | ✅ Tool present | Verify: K8s API server audit policy at `RequestResponse` level for sensitive resources; Vault audit backend enabled (mandatory — OpenBao has this on by default). |
| **Information disclosure** (admin exfiltration) | Network policy (egress), Wazuh FIM, auditd | ⚠️ Partial | **Gap: egress filtering is not explicitly in the BOM.** Cilium supports egress policy but it must be configured. Without egress control, a compromised admin can exfiltrate data to arbitrary destinations. NIS2 Art 21.2(e) implies network segmentation. |
| **Elevation of privilege** (lateral movement after compromise) | SELinux/AppArmor, seccomp, Vault least-privilege, RBAC | ✅ Tool present | Verify: separate credentials per system (no shared root); jump host or PAM for infrastructure access; no persistent root shells. |

### TB5: Data at rest (storage, backups, evidence)

| Threat | Stack component | Control status | Gap / risk |
|--------|----------------|----------------|------------|
| **Information disclosure** (backup theft, storage breach) | ZFS encryption, LUKS, Vault transit encryption, SOPS+age | ⚠️ Partial | **Verify: ZFS native encryption or LUKS is enabled on all volumes holding sensitive data.** ZFS is in the BOM for integrity (checksumming) but encryption is not explicitly required. Backup encryption (restic/borg) is standard. |
| **Tampering** (backup corruption, evidence manipulation) | ZFS checksumming + scrub, WORM/S3 object lock for evidence, Sigstore Rekor transparency | ✅ Tool present | Verify: scrub schedule active; evidence store has object lock with retention; Rekor entries for signed artifacts. |
| **DoS** (ransomware, storage destruction) | ZFS snapshots, off-site backups (restic/borg), Velero, tested restores | ✅ Tool present | Verify: 3-2-1 backup rule; at least one backup target is air-gapped or immutable; restore tested periodically with evidence. |

---

## 2 — Identified gaps (ranked by risk)

| # | Gap | STRIDE | Regulatory req | Severity | Remediation | Effort |
|---|-----|--------|---------------|----------|-------------|--------|
| 1 | **No WAF / DDoS protection** for internet-facing services | DoS, Tampering | NIS2 21.2(e), CRA Annex I DoS resilience | High (if internet-facing) | Add ModSecurity/Coraza WAF or cloud DDoS; add rate limiting at Ingress | M |
| 2 | **Egress filtering not enforced** | Info disclosure | NIS2 21.2(e) network security | High | Implement default-deny egress via Cilium NetworkPolicy; allow-list required external endpoints | M |
| 3 | **mTLS east-west conditional** — not enforced if service mesh not deployed | Spoofing, Tampering | NIS2 21.2(h) encryption; CRA Annex I data in transit | Medium–High (depends on threat model) | Deploy Cilium mutual auth or Istio/Linkerd mTLS; or accept risk with documented justification | M–L |
| 4 | **Resource limits not enforced via policy** | DoS (internal) | CRA Annex I DoS resilience | Medium | Add Kyverno policy requiring resource limits/requests on all workloads | S |
| 5 | **No secret scanning in CI pipeline** (Gitleaks/truffleHog absent) | Info disclosure | NIS2 21.2(e), GDPR Art 32 | Medium | Add Gitleaks or truffleHog pre-commit hook + CI gate | S |
| 6 | **Dependency confusion protection not explicit** | Tampering | CRA Annex I supply chain | Medium | Configure registry scoping/namespaces; pin internal package names; Kyverno registry allow-list partially mitigates | S |
| 7 | **Storage encryption at rest not explicitly mandated** | Info disclosure | GDPR Art 32(1)(a) encryption; NIS2 21.2(h) | Medium | Enable ZFS native encryption or LUKS on all volumes with personal/sensitive data; document encryption scope | S–M |
| 8 | **K8s API audit policy level not specified** | Repudiation | NIS2 21.2 logging; CRA Annex I event logging | Low–Medium | Set API server audit policy to RequestResponse for sensitive resources; forward to Loki/OpenSearch | S |

---

## 3 — Controls that are present but need verification

These are not gaps — the tool is in the BOM — but the control is only effective **if configured correctly**. An auditor will check these.

| Control | What to verify | Evidence to produce |
|---------|---------------|---------------------|
| Keycloak MFA | Enforced for all user-facing and admin services, not just selectively | Realm config export showing MFA policy; login audit logs showing MFA challenge |
| SELinux/AppArmor in enforcing mode | `enforcing` on all prod nodes, not `permissive` | `getenforce` / `aa-status` output from all prod nodes; Ansible fact collection |
| Pod Security Admission | `restricted` baseline in all prod namespaces | Namespace labels showing PSA enforcement; Kyverno policy backup |
| Cilium network policy default-deny | Default deny ingress AND egress in prod namespaces | `kubectl get networkpolicy -A` showing default deny; Hubble flow logs showing denied traffic |
| Vault/OpenBao audit backend | Audit logging enabled (not optional) | Vault audit device config; sample audit log entries |
| Kyverno admission in enforce mode | Not just `audit` mode in prod | Kyverno policy mode field; admission denial events in logs |
| Signed image enforcement | Kyverno/Gatekeeper rejects unsigned images in prod | Test: attempt to deploy unsigned image; capture rejection event |
| Backup restore tested | Not just backed up — restored and verified | Restore test log with date, duration, data integrity check result |
| chrony sync accuracy | All nodes synced within acceptable offset | `chronyc tracking` output from all nodes; alerting on drift > threshold |
| Falco rules coverage | Rules cover container escape, privilege escalation, unexpected network, crypto mining | Falco rules file in VCS; test: trigger a rule and verify alert arrives |

---

## 4 — Summary assessment

| Domain | Tool coverage | Control enforcement | Evidence readiness | Overall |
|--------|--------------|--------------------|--------------------|---------|
| Identity / AuthN / MFA | ✅ Strong | ⚠️ Verify MFA scope | ⚠️ Need audit log export | Adequate if verified |
| Secrets management | ✅ Strong | ✅ Dynamic secrets + least-privilege | ✅ Vault audit log | Strong |
| Network perimeter | ⚠️ Missing WAF/DDoS | ⚠️ Egress not enforced | ⚠️ Flow logs need forwarding | **Gap** |
| East-west encryption | ⚠️ Conditional (mTLS) | ⚠️ Depends on mesh deployment | ⚠️ | **Conditional gap** |
| Container runtime security | ✅ Strong (SELinux/AppArmor + seccomp + Falco) | ⚠️ Verify enforcing mode | ⚠️ Need policy export evidence | Adequate if verified |
| Supply chain / signing | ✅ Strong | ✅ Admission enforcement | ✅ SBOM + signatures + Rekor | Strong |
| Vulnerability management | ✅ Strong | ✅ Scan + VEX + update automation | ✅ Scan reports as artifacts | Strong |
| Logging / forensics | ✅ Strong | ⚠️ K8s audit policy level; retention | ⚠️ Need retention policy doc | Adequate if verified |
| Backup / DR | ✅ Strong | ⚠️ Verify 3-2-1 and restore tests | ⚠️ Need periodic test evidence | Adequate if verified |
| Policy-as-code / admission | ✅ Strong | ⚠️ Verify enforce (not audit) mode | ✅ Policy in VCS | Adequate if verified |
| Data at rest encryption | ⚠️ Partial (not explicit) | ⚠️ Verify ZFS/LUKS enabled | ⚠️ Need encryption scope doc | **Gap** |
| Secret scanning (CI) | ❌ Missing | — | — | **Gap** |

---

## 5 — Recommended additions to the BOM

| Component | Purpose | Tier | Boundary enforced | License |
|-----------|---------|------|-------------------|---------|
| Gitleaks or truffleHog | Secret scanning in CI + pre-commit | T1 | CI pipeline / code provenance | MIT / AGPL 3.0 |
| ModSecurity / Coraza WAF | WAF for internet-facing Ingress | T1 (if internet-facing) | External admission | Apache 2.0 (Coraza) |
| Cilium egress policy (config, not new tool) | Default-deny egress | T0 | Network boundary | Already in BOM (Cilium) |
| Kyverno resource limit policy (config, not new tool) | Enforce resource limits on all pods | T1 | Resource boundary | Already in BOM (Kyverno) |

Three of the four are **configuration of existing tools**, not new dependencies. Only secret scanning (Gitleaks/Coraza) is a new addition.

---

*Assessment [I,80] — based on BOM inventory. Actual sufficiency requires verification of enforcement state and evidence capture per §3 table. Schedule a control verification sprint before audit.*
