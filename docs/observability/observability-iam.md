# Stack BOM — Observability & IAM Architecture (Appendix E)

**Date:** 2026-03-05
**Scope:** Full request-to-evidence flow for conventional (non-AI) workloads: IAM, AuthN/AuthZ, service execution, logging, tracing, metrics, alerting, forensics, and evidence capture.
**Status:** DRAFT

---

## Design principle

Every request that enters the platform must produce a traceable chain from identity assertion through authorization decision, service execution, observable outcome, and (where required) signed evidence. No gap in the chain means no gap in the audit trail.

---

## 1 — End-to-end request flow

```
                    EXTERNAL USER / SYSTEM
                           │
                           ▼
              ┌─────────────────────────┐
           ①  │ DNS + TLS termination   │  chrony-synced time on all nodes
              │ (Ingress: NGINX/Traefik)│  TLS 1.2+ only; HSTS
              └────────────┬────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
           ②  │ API Gateway (Kong)      │  OIDC token validation (Keycloak)
              │                         │  Rate limiting per consumer
              │                         │  Request validation (OpenAPI)
              │                         │  WAF (Coraza)
              │                         │  Access log → OTel + OpenSearch
              └────────────┬────────────┘
                           │  Bearer token (JWT) forwarded
                           ▼
              ┌─────────────────────────┐
           ③  │ Service (Pod)           │  Extracts JWT claims; applies RBAC
              │                         │  OTel SDK: creates span with
              │                         │    trace_id, user_id, action,
              │                         │    resource, outcome
              │                         │  Structured log per request
              │                         │  Prometheus metrics: latency,
              │                         │    error rate, saturation
              └────────────┬────────────┘
                           │  Service-to-service calls
                           ▼
              ┌─────────────────────────┐
           ④  │ East-west (Cilium mTLS) │  Identity: SPIFFE/workload cert
              │                         │  NetworkPolicy: default-deny
              │                         │  Cilium flow logs → Hubble
              └────────────┬────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
           ⑤  │ Data layer              │  Vault dynamic credentials
              │ (PostgreSQL / Redis /   │  Short-lived lease; access logged
              │  OpenSearch / MinIO)    │  pgAudit for PostgreSQL queries
              └────────────┬────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
           ⑥  │ Observability pipeline  │  OTel Collector: receives traces,
              │                         │    metrics, logs from all layers
              │                         │  Routes to:
              │                         │   - Prometheus (metrics)
              │                         │   - Loki/OpenSearch (logs)
              │                         │   - Tempo/Jaeger (traces)
              │                         │  Alertmanager: fires on SLO breach
              └────────────┬────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
           ⑦  │ Security pipeline       │  Wazuh: correlates security events
              │                         │  Falco: runtime anomaly detection
              │                         │  auditd: OS-level syscall audit
              │                         │  Kyverno: admission decisions
              └────────────┬────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
           ⑧  │ Evidence store          │  MinIO WORM + OpenSearch catalogue
              │                         │  Daily hash chain + cosign
              │                         │  Rekor transparency log
              └─────────────────────────┘
```

---

## 2 — IAM architecture

### 2.1 — Identity provider: Keycloak

```
┌──────────────────────────────────────────────────────────────┐
│                        KEYCLOAK                               │
│                                                               │
│  Realms:                                                      │
│  ├── platform-realm (infrastructure operators)               │
│  │   ├── MFA: mandatory (TOTP or WebAuthn/FIDO2)            │
│  │   ├── Clients: GitLab, Argo CD, Grafana, Kong,           │
│  │   │   Vault, OpenSearch Dashboards, MinIO Console         │
│  │   └── Roles: platform-admin, platform-operator,           │
│  │       platform-viewer, security-auditor                   │
│  │                                                            │
│  └── application-realm (application users / service accounts)│
│      ├── MFA: mandatory for human users; N/A for SA          │
│      ├── Clients: application APIs via Kong                  │
│      ├── Roles: per-application RBAC                         │
│      ├── Groups: team-based, mapped to K8s namespaces        │
│      └── Service accounts: scoped per service; short-lived   │
│          tokens; monitored for anomalous usage               │
│                                                               │
│  Federation (optional):                                       │
│  ├── LDAP/AD: employee directory sync                        │
│  └── External IdP brokering: partner OIDC/SAML              │
│                                                               │
│  Auth flows:                                                  │
│  ├── Browser: Authorization Code + PKCE → Kong → Keycloak   │
│  ├── Machine-to-machine: Client Credentials → Kong → service │
│  ├── CI/CD: GitLab OIDC → Vault (secret retrieval)          │
│  │          GitLab OIDC → Fulcio (cosign keyless signing)    │
│  └── K8s API: OIDC token → K8s API server → RBAC binding    │
│                                                               │
│  Token policy:                                                │
│  ├── Access token lifetime: 5 minutes (short)                │
│  ├── Refresh token lifetime: 8 hours (session-bound)         │
│  ├── Offline token: disabled unless explicitly required       │
│  ├── Token audience: scoped per client (not wildcard)        │
│  └── Token introspection: preferred over local JWT           │
│      validation for sensitive operations                      │
│                                                               │
│  Audit events:                                                │
│  ├── LOGIN, LOGIN_ERROR, LOGOUT                              │
│  ├── REGISTER, UPDATE_PROFILE, RESET_PASSWORD                │
│  ├── CLIENT_LOGIN, CLIENT_LOGIN_ERROR                        │
│  ├── GRANT_ROLE, REVOKE_ROLE                                 │
│  ├── ADMIN operations (realm config changes)                 │
│  └── All events → Keycloak event listener → OTel / syslog   │
│      → OpenSearch (evidence catalogue)                       │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 — Authorization model

| Layer | Mechanism | Tool | Evidence |
|-------|-----------|------|----------|
| API gateway | OIDC token validation; consumer-level rate limiting | Kong + Keycloak | Kong access log (allow/deny per request) |
| Application | JWT claims → RBAC/ABAC decision in service code | Service logic + OPA (optional) | Structured log: user, action, resource, decision |
| Kubernetes | K8s RBAC: RoleBinding per namespace; ClusterRole for platform ops | kubectl / K8s API server | K8s API audit log (RequestResponse) |
| Infrastructure | Vault policies: path-based ACLs; dynamic credentials | Vault / OpenBao | Vault audit log (every secret access) |
| Database | Row-level security (PostgreSQL RLS) or application-enforced | PostgreSQL + pgAudit | Query audit log |
| Network | Cilium NetworkPolicy: default-deny; L3/L4 + L7 rules | Cilium | Hubble flow logs (allow/deny per flow) |

### 2.3 — Service account governance

Service accounts are identity debt — every one is a lateral movement path.

| Control | Implementation | Evidence |
|---------|---------------|----------|
| Inventory | All service accounts registered in Keycloak with owner, purpose, expiry | SA inventory export (quarterly) |
| Least privilege | Scoped to one service, one namespace; no cluster-admin for workloads | RBAC audit (quarterly) |
| Short-lived credentials | Vault dynamic credentials (lease TTL ≤ 1 hour); K8s projected service account tokens (expiry) | Vault lease records; K8s token TTL config |
| Rotation | Vault handles rotation automatically via lease expiry; static secrets rotated quarterly | Rotation logs |
| Monitoring | Alert on SA usage outside expected pattern (time, source IP, action) | Wazuh correlation rules |
| Review | Quarterly access review: owner confirms SA is still needed | Access review completion records |

### 2.4 — Privileged access management (PAM)

| Pattern | Implementation | Tool |
|---------|---------------|------|
| JIT access | Vault with short-lived dynamic credentials; SSH certificates with 1-hour validity | Vault SSH secret engine |
| Break-glass | Sealed emergency credentials in Vault; require unsealing by 2 people; mandatory post-incident review | Vault + documented procedure |
| Session audit | SSH sessions logged via auditd; K8s exec logged via API audit; Vault audit log | auditd + K8s API audit + Vault audit |
| Admin MFA | Mandatory FIDO2/WebAuthn for all platform-admin operations | Keycloak auth flow |
| No persistent root | SSH root login disabled; sudo via named accounts only; all sudo logged | PAM config + auditd |

---

## 3 — Observability architecture

### 3.1 — Three pillars + security signals

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATA SOURCES (per layer)                     │
│                                                                  │
│  Application:   OTel SDK (traces + metrics + logs)               │
│  Kubernetes:    K8s API audit, kubelet metrics, kube-state       │
│  Networking:    Cilium Hubble flow logs, Ingress access logs     │
│  Infrastructure: node_exporter, ZFS/Ceph exporters, DCGM        │
│  Identity:      Keycloak events, Vault audit, K8s RBAC audit    │
│  Security:      Wazuh agents, Falco, auditd, Kyverno events     │
│                                                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     COLLECTION LAYER                             │
│                                                                  │
│  OTel Collector (central):                                       │
│  ├── Receives: OTLP (traces, metrics, logs) from all services   │
│  ├── Processors:                                                │
│  │   ├── Batch (reduce cardinality)                             │
│  │   ├── Attributes (add cluster, namespace, service metadata)  │
│  │   ├── Redaction (strip PII from spans/logs before storage)   │
│  │   ├── Sampling (tail-based: keep errors + slow; sample OK)   │
│  │   └── Transform (rename, drop unused attributes)             │
│  └── Exports to:                                                │
│      ├── Prometheus (metrics via remote_write)                  │
│      ├── Tempo (traces via OTLP)                                │
│      ├── Loki or OpenSearch (logs via OTLP or Loki exporter)   │
│      └── MinIO evidence bucket (security-relevant logs)         │
│                                                                  │
│  Fluent Bit / Vector (log shipping):                             │
│  ├── Receives: journald, container logs, audit logs             │
│  ├── Transforms: parse, enrich, redact                          │
│  └── Ships to: OpenSearch (searchable) + MinIO (evidence WORM)  │
│                                                                  │
│  Prometheus (scrape):                                            │
│  ├── Scrapes: node_exporter, kube-state-metrics, cAdvisor,      │
│  │   application /metrics, Cilium, Ceph, ZFS, DCGM              │
│  └── Alertmanager: evaluates recording + alerting rules          │
│                                                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     STORAGE LAYER                                │
│                                                                  │
│  Metrics:  Prometheus (hot, 15d) → Thanos/VictoriaMetrics (1y+) │
│  Traces:   Tempo (hot, 7d) → object storage (30d)               │
│  Logs:     OpenSearch (hot, 30d) → ILM warm/cold (1y)           │
│  Security: Wazuh indexer → OpenSearch (security index, 1y)       │
│  Evidence: MinIO WORM (per retention tier, see Appendix C)       │
│                                                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CONSUMPTION LAYER                            │
│                                                                  │
│  Grafana:                                                        │
│  ├── Datasources: Prometheus, Loki, Tempo, OpenSearch           │
│  ├── Dashboards:                                                │
│  │   ├── Platform overview (node/pod/namespace health)          │
│  │   ├── Service golden signals (latency, errors, traffic, sat) │
│  │   ├── SLO burn-rate (per service)                            │
│  │   ├── Identity: auth success/failure, token issuance rate    │
│  │   ├── Security: Wazuh alerts, Falco events, admission deny  │
│  │   ├── Storage: ZFS health, Ceph OSD status, backup age      │
│  │   ├── Evidence: artifact count per type/project/month        │
│  │   └── Cost: resource utilization per namespace/team          │
│  │                                                               │
│  ├── Alerting: Grafana Alerting or Alertmanager (choose one)    │
│  └── On-call: Alert routing → PagerDuty/Opsgenie (or OSS)      │
│                                                                  │
│  OpenSearch Dashboards:                                          │
│  ├── Log exploration (full-text search across all log streams)  │
│  ├── Security event investigation (Wazuh + Falco correlation)   │
│  └── Evidence catalogue query (Appendix C §5)                   │
│                                                                  │
│  Wazuh Dashboard:                                                │
│  ├── Security alerts, FIM, vulnerability detection              │
│  ├── Compliance dashboards (PCI DSS, GDPR, NIST mapped)        │
│  └── Agent health and coverage                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 — Structured logging standard

Every service must emit structured logs with these required fields:

| Field | Source | Purpose |
|-------|--------|---------|
| `timestamp` | chrony-synced system clock | Forensic timeline |
| `trace_id` | OTel context propagation | Cross-service correlation |
| `span_id` | OTel context propagation | Request-level correlation |
| `service.name` | OTel resource attribute | Service identification |
| `service.namespace` | K8s namespace | Blast radius scoping |
| `user.id` | JWT `sub` claim (hashed if PII) | AuthZ audit trail |
| `action` | Application logic | What was attempted |
| `resource` | Application logic | What was accessed |
| `outcome` | Application logic (`success` / `denied` / `error`) | AuthZ evidence |
| `http.method` | OTel HTTP semantic conventions | Request context |
| `http.status_code` | OTel HTTP semantic conventions | Response classification |
| `error.type` | OTel error conventions | Failure categorisation |
| `log.level` | Application | Severity routing |

**PII handling:** `user.id` is logged as a hash unless the service is the identity provider itself. Actual user identifiers are resolvable via Keycloak admin API using the hashed ID, but are not stored in general log streams. This satisfies GDPR data minimisation while maintaining auditability. [I] {80}

### 3.3 — Tracing architecture

```
Request enters (Kong)
  │
  │  Kong creates root span: trace_id + span_id
  │  Propagation: W3C TraceContext header (traceparent)
  │
  ▼
Service A ────── OTel SDK creates child span
  │                 Attributes: user_id, action, resource, outcome
  │
  ├── DB call ── OTel auto-instrumentation: db.statement (redacted), duration
  │
  ├── Cache hit ── OTel auto-instrumentation: cache.hit, duration
  │
  └── Service B call ── child span; traceparent propagated
       │
       └── Service C call ── child span; traceparent propagated
            │
            └── External API call ── child span; sanitised
                 (no internal headers forwarded externally)
```

**Sampling strategy:**
- Errors and slow requests (>p99): always sampled (100%)
- Security-relevant events (auth failure, policy denial): always sampled
- Normal traffic: tail-based sampling at OTel Collector (10–20% in prod)
- Debug: head-based 100% sampling in staging/dev

### 3.4 — Metrics architecture

| Layer | Key metrics | Source | Alerting threshold |
|-------|-------------|--------|-------------------|
| **Service (golden signals)** | `http_request_duration_seconds` (histogram), `http_requests_total` (counter by status), `http_active_requests` (gauge) | OTel SDK / Prometheus client | p99 latency > SLO; error rate > burn rate |
| **Kubernetes** | Pod restarts, OOMKills, CPU/memory utilization, pending pods | kube-state-metrics + cAdvisor | Restarts > 3/hour; OOMKill any; pending > 5min |
| **Node** | CPU, memory, disk I/O, network, load | node_exporter | CPU > 80% sustained; disk > 85%; memory > 90% |
| **Networking** | Connection rate, flow drops, DNS latency | Cilium metrics + CoreDNS | Flow drops > 0 (indicates policy misconfiguration or attack) |
| **Storage** | ZFS pool health, scrub errors, Ceph OSD status, PG state | zfs_exporter, ceph_exporter | Any non-ONLINE ZFS state; any non-HEALTH_OK Ceph |
| **Identity** | Auth success/failure rate, token issuance rate, admin operations | Keycloak metrics exporter | Failed auth spike (>3× baseline); admin operation outside window |
| **Security** | Wazuh alert count by severity, Falco event rate, admission denials | Wazuh/Falco/Kyverno metrics | Any critical severity; Falco event rate spike |
| **Backup** | Last successful backup age, last restore test age | Custom exporter / Prometheus pushgateway | Backup age > 1.5× interval; restore test > 30 days |

### 3.5 — Alert design

| Category | Alert | Severity | Routing | Runbook |
|----------|-------|----------|---------|---------|
| **SLO** | Error budget burn rate > 10× (fast burn, 5min window) | Critical | On-call (PagerDuty/Opsgenie) | Investigate service; check recent deploys; consider rollback |
| **SLO** | Error budget burn rate > 2× (slow burn, 6h window) | Warning | Slack + ticket | Investigate trend; may be gradual degradation |
| **Security** | Failed auth spike (>3× baseline in 15min) | Critical | Security on-call | Credential stuffing? Account lockout? Check source IPs |
| **Security** | Falco: container escape detected | Critical | Security on-call + platform on-call | Isolate node; forensic capture; incident response |
| **Security** | Kyverno: unsigned image admission attempt | Warning | Security Slack | Verify: CI misconfiguration or attack? |
| **Identity** | Vault: root token used | Critical | Security on-call | Should never happen in prod; investigate immediately |
| **Identity** | Service account used outside expected hours/IP | Warning | Security Slack | Compromised credential? Legitimate automation? |
| **Infrastructure** | ZFS pool degraded | Critical | Platform on-call | Check device errors; prepare replacement |
| **Infrastructure** | Ceph HEALTH_ERR | Critical | Platform on-call | Check OSD status; begin recovery |
| **Infrastructure** | Backup age > 1.5× interval | Warning | Platform on-call | Check backup job; verify storage |
| **Infrastructure** | chrony offset > 100ms | Warning | Platform on-call | Time integrity risk; check NTP sources |
| **Evidence** | Hash chain verification failed | Critical | Security on-call | Potential evidence tampering; investigate immediately |

---

## 4 — Auth event logging and evidence chain

### 4.1 — What must be logged (non-negotiable for NIS2/GDPR audit)

| Event category | Source | Fields | Retention | Regulatory driver |
|----------------|--------|--------|-----------|-------------------|
| Authentication (success) | Keycloak | timestamp, user_id, client_id, auth_method (password/MFA/cert), source_ip, realm | 1 year | NIS2 Art 21.2(j); GDPR Art 32 |
| Authentication (failure) | Keycloak | timestamp, attempted_user, client_id, failure_reason, source_ip | 1 year | NIS2 Art 21.2(j); ISO 27001 A.8.15 |
| Token issuance | Keycloak | timestamp, user_id, client_id, token_type, scope, audience, expiry | 1 year | NIS2; audit trail |
| Authorization decision | Service / OPA | timestamp, trace_id, user_id, action, resource, decision (allow/deny), policy_version | 1 year | NIS2 Art 21.2(i); GDPR Art 32 |
| Privileged operation | Vault audit + K8s API audit + auditd | timestamp, user_id, operation, target, outcome | 1 year | NIS2 Art 21.2(i); ISO 27001 A.8.2 |
| Role/permission change | Keycloak admin events | timestamp, admin_id, target_user, role_added/removed | 3 years | NIS2; GDPR (if affects data access) |
| Secret access | Vault audit log | timestamp, identity, secret_path, operation (read/create/delete), lease_id | 1 year | NIS2 Art 21.2(h); ISO 27001 A.8.2 |
| API access | Kong access log | timestamp, consumer_id, route, method, status, latency, source_ip | 1 year | NIS2 Art 21.2(e); CRA Annex I logging |
| Admission decision | Kyverno event log | timestamp, namespace, resource, policy, decision (allow/deny) | 1 year | NIS2 Art 21.2(e); supply chain |
| Network flow (denied) | Cilium Hubble | timestamp, source_pod, dest_pod, port, verdict (DROPPED) | 90 days | NIS2 Art 21.2(e) |
| File integrity change | Wazuh FIM | timestamp, file_path, change_type, hash_before, hash_after | 1 year | NIS2 Art 21.2(e); forensics |
| OS syscall audit | auditd | timestamp, uid, syscall, path, outcome | 1 year | NIS2; forensics |

### 4.2 — Log pipeline routing

```
┌─────────────────────────────────────────────────────────────┐
│                    LOG ROUTING RULES                         │
│                                                              │
│  Fluent Bit / Vector input → parse → enrich → route:        │
│                                                              │
│  IF source == "keycloak-events"                              │
│    → OpenSearch (index: auth-events-*)                       │
│    → MinIO evidence (evidence/runtime/{date}/auth/)          │
│                                                              │
│  IF source == "vault-audit"                                  │
│    → OpenSearch (index: vault-audit-*)                       │
│    → MinIO evidence (evidence/runtime/{date}/vault/)         │
│                                                              │
│  IF source == "k8s-api-audit"                                │
│    → OpenSearch (index: k8s-audit-*)                         │
│    → MinIO evidence (evidence/runtime/{date}/k8s-api/)       │
│                                                              │
│  IF source == "kyverno-events"                               │
│    → OpenSearch (index: admission-events-*)                  │
│    → MinIO evidence (evidence/runtime/{date}/kyverno/)       │
│                                                              │
│  IF source == "falco"                                        │
│    → OpenSearch (index: falco-events-*)                      │
│    → Wazuh (correlation)                                     │
│    → MinIO evidence (evidence/runtime/{date}/falco/)         │
│                                                              │
│  IF source == "application" AND log.level >= "WARN"          │
│    → OpenSearch (index: app-logs-*)                          │
│    (INFO-level: OpenSearch only; no evidence store)           │
│                                                              │
│  IF source == "wazuh-alerts" AND severity >= "HIGH"          │
│    → OpenSearch (index: wazuh-alerts-*)                      │
│    → MinIO evidence (evidence/runtime/{date}/wazuh/)         │
│    → Alertmanager webhook                                    │
│                                                              │
│  DEFAULT:                                                    │
│    → OpenSearch (index: general-logs-*)                      │
│                                                              │
│  All routes to MinIO evidence:                               │
│    → Subject to daily hash chain (Appendix C §3.3)           │
│    → WORM retention per tier                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 — Correlation: connecting identity to action to evidence

An auditor asks: "Show me everything user X did on 2026-02-15."

The query path:

```
1. OpenSearch: auth-events-* WHERE user_id = hash(X) AND date = 2026-02-15
   → Returns: login timestamps, client_ids, source_ips, auth methods

2. OpenSearch: app-logs-* WHERE user.id = hash(X) AND date = 2026-02-15
   → Returns: all application actions with trace_ids

3. Tempo: traces WHERE user.id = hash(X) AND date = 2026-02-15
   → Returns: full request flows across services (via trace_id)

4. OpenSearch: vault-audit-* WHERE identity contains X AND date = 2026-02-15
   → Returns: all secret access by X

5. OpenSearch: k8s-audit-* WHERE user.username = X AND date = 2026-02-15
   → Returns: all K8s API actions (kubectl, API calls)

6. Grafana: unified dashboard linking all five queries
   → Single timeline view of user X's activity
```

The key is `user.id` (hashed consistently across all systems) and `trace_id` (propagated via W3C TraceContext). These two fields are the correlation keys that make the entire chain queryable.

---

## 5 — Access review and governance cycle

| Activity | Frequency | Input | Output (evidence) | Owner |
|----------|-----------|-------|-------------------|-------|
| **User access review** | Quarterly | Keycloak role/group export | Review decisions (retain/revoke) per user/role with justification | Team managers |
| **Service account review** | Quarterly | SA inventory export from Keycloak + Vault | Review decisions; unused SAs revoked | Platform team |
| **Privileged access review** | Monthly | Vault audit log analysis + K8s cluster-admin bindings | Privileged usage report; anomalies investigated | Security lead |
| **RBAC drift check** | Monthly (automated) | Current RBAC bindings vs. approved baseline in Git | Drift report (any binding not in VCS = unauthorized) | Platform team |
| **Network policy review** | Quarterly | Cilium NetworkPolicy export | Policy coverage report; namespaces without default-deny flagged | Platform team |
| **Failed auth analysis** | Weekly (automated) | Keycloak failed auth events | Report: source IPs, targeted accounts, pattern analysis | Security team |
| **Token lifetime audit** | Quarterly | Keycloak client config export | Clients with access token > 5min or refresh token > 8h flagged | Security lead |

All review outputs → signed → evidence store (MinIO WORM) → catalogued in OpenSearch.

---

## 6 — SLI / SLO framework for conventional services

### 6.1 — Standard SLI definitions

| SLI | Measurement | Good event definition | Source |
|-----|-------------|----------------------|--------|
| **Availability** | Ratio of successful requests to total requests | HTTP status < 500 (server errors) | OTel / Prometheus |
| **Latency** | Request duration distribution | p99 < target (per service) | OTel histogram |
| **Correctness** | Ratio of correct responses | Application-defined (e.g., valid JSON, expected schema) | Application metrics |
| **Freshness** | Age of data served | Data age < staleness threshold | Application metrics |

### 6.2 — SLO template (per service)

```yaml
service: payment-api
slos:
  - name: availability
    target: 99.9%  # 43.8 min downtime/month
    window: 30d rolling
    sli: http_requests_total{status!~"5.."} / http_requests_total
    burn_rate_alerts:
      - speed: fast    # 14.4× burn, 1h window
        severity: critical
      - speed: slow    # 6× burn, 6h window
        severity: warning

  - name: latency_p99
    target: 99.0%  # 1% of requests may exceed threshold
    threshold: 500ms
    window: 30d rolling
    sli: |
      histogram_quantile(0.99,
        rate(http_request_duration_seconds_bucket[5m]))
      < 0.5
    burn_rate_alerts:
      - speed: fast
        severity: warning

  - name: error_budget_remaining
    target: > 0%
    dashboard: grafana/slo-payment-api
    escalation: if budget exhausted → change freeze until recovery
```

---

## 7 — Forensic readiness

| Requirement | Implementation | Evidence |
|-------------|---------------|----------|
| **Timeline reconstruction** | All events use chrony-synced timestamps; correlated via trace_id and user.id | chrony sync logs; OTel traces; structured logs |
| **Chain of custody** | Evidence artifacts signed (cosign) and stored in WORM | cosign bundles; Rekor entries; MinIO Object Lock |
| **Non-repudiation** | Auth decisions logged with identity; admin operations logged with MFA-verified identity | Keycloak events; Vault audit; K8s API audit |
| **Tamper detection** | Daily hash chain over evidence store; ZFS checksumming on underlying storage | Hash chain verification logs; ZFS scrub reports |
| **Preservation** | MinIO COMPLIANCE-mode Object Lock; retention per regulatory tier | Retention policy config; Object Lock verification |
| **Independent verification** | Rekor transparency log; auditor can verify without accessing internal systems | Rekor entries; public verification |

---

## 8 — What this adds to the BOM

No new tools in this appendix — it describes how the **existing BOM components connect** for conventional workloads. AI-specific components (Kong, LiteLLM, GenAI instrumentation) are defined in Appendix D §15–§17 and use the same observability pipeline described here, with GenAI-specific OTel spans routed through the same OTel Collector (see Appendix D Part 4 for OWASP LLM mapping and GenAI semantic conventions).

| Component | Role in this architecture | BOM section |
|-----------|--------------------------|-------------|
| Keycloak | Identity provider; auth event source | §1 |
| Vault / OpenBao | Secret boundary; PAM; audit trail | §1 |
| Kong | API gateway; north-south access control + logging | §15 (Appendix D) |
| Cilium | East-west mTLS; network policy; flow logs | §3 |
| OTel Collector | Trace/metric/log collection + routing | §5 |
| Prometheus + Alertmanager | Metric storage + alerting | §5 |
| Grafana | Dashboards for all layers | §5 |
| Loki / OpenSearch | Log storage + search | §5 |
| Tempo | Trace storage | §5 |
| Fluent Bit / Vector | Log shipping + transform + routing | §5 |
| Wazuh | SIEM + FIM + security correlation | §5 |
| Falco | Runtime anomaly detection | §6 |
| auditd / journald | OS-level forensic trail | §5 |
| Kyverno | Admission decisions | §2 |
| chrony | Time sync (evidence timestamp integrity) | §5 |
| MinIO (WORM) | Evidence store | Appendix C |
| OpenSearch (catalogue) | Evidence metadata index | Appendix C §5 |

**This appendix is the wiring diagram that connects them.** The BOM is the parts list; this is the assembly instructions.

---

*All architecture claims [I,80]. Tool configuration details [S,75] — verify against current upstream documentation. Retention periods [S,80] — verify against regulatory requirements and legal counsel.*
