# Stack BOM — License Audit (Appendix A)

**Date:** 2026-03-05
**Purpose:** Verify every BOM component is open-source and freely available for internal use. Flag license risks.

---

## License classification

| Category | Meaning | Risk for internal use |
|----------|---------|----------------------|
| **OSS** | OSI-approved open-source license | None |
| **BSL** | Business Source License (source-available, not OSI-approved) | Low for internal use; restricts competitive commercial offerings |
| **Open-core** | OSS base with proprietary enterprise features | Depends on which features you need |
| **Proprietary** | Closed-source commercial | Requires license purchase |
| **OSS-fork** | OSS fork of a BSL/relicensed project | None (verify fork stays current) |

---

## Full component license table

### §1 — Identity, secrets, trust anchors

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Keycloak | Apache 2.0 | OSS | Yes | CNCF project |
| Vault (HashiCorp) | BSL 1.1 | BSL | Yes (internal) | Cannot offer as competitive hosted service. Converts to MPL 2.0 after 4 years per release. |
| OpenBao | MPL 2.0 | OSS-fork | Yes | LF fork of Vault 1.14 (last MPL release). API-compatible. Missing some Enterprise features (DR replication, Sentinel). Community-driven, GitLab is a major backer. |
| SOPS | MPL 2.0 | OSS | Yes | |
| age | BSD 3-Clause | OSS | Yes | |
| External Secrets Operator | Apache 2.0 | OSS | Yes | |
| cert-manager | Apache 2.0 | OSS | Yes | CNCF project |
| GPG | GPL 3.0 | OSS | Yes | |

### §2 — Supply chain integrity

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Syft | Apache 2.0 | OSS | Yes | Anchore project |
| cosign (Sigstore) | Apache 2.0 | OSS | Yes | OpenSSF project |
| Rekor | Apache 2.0 | OSS | Yes | OpenSSF project |
| in-toto | Apache 2.0 | OSS | Yes | CNCF project |
| Trivy | Apache 2.0 | OSS | Yes | Aqua Security project |
| osv-scanner | Apache 2.0 | OSS | Yes | Google project |
| Kyverno | Apache 2.0 | OSS | Yes | CNCF project |
| OPA / Gatekeeper | Apache 2.0 | OSS | Yes | CNCF graduated |
| ORT | Apache 2.0 | OSS | Yes | |
| Renovate | AGPL 3.0 | OSS | Yes (self-hosted) | AGPL applies to the Renovate app itself; using it to create PRs does not make your code AGPL |
| Grype | Apache 2.0 | OSS | Yes | Anchore project |

### §3 — Platform core (Kubernetes / containers)

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Kubernetes | Apache 2.0 | OSS | Yes | CNCF graduated |
| OpenShift | Apache 2.0 (OKD) / Proprietary (RHOCP) | Open-core | OKD: Yes. RHOCP: Requires subscription. | OKD is the upstream; Red Hat OpenShift Container Platform requires subscription for support + entitlements |
| containerd | Apache 2.0 | OSS | Yes | CNCF graduated |
| Docker CE | Apache 2.0 | OSS | Yes | Docker Desktop has separate commercial terms; Docker Engine (CE) is Apache 2.0 |
| Podman | Apache 2.0 | OSS | Yes | |
| Harbor | Apache 2.0 | OSS | Yes | CNCF graduated |
| Cilium | Apache 2.0 | OSS | Yes | CNCF graduated |
| Calico | Apache 2.0 | OSS | Yes | |
| CoreDNS | Apache 2.0 | OSS | Yes | CNCF graduated |
| MetalLB | Apache 2.0 | OSS | Yes | |
| Helm | Apache 2.0 | OSS | Yes | CNCF graduated |
| Istio | Apache 2.0 | OSS | Yes | CNCF graduated |
| Linkerd | Apache 2.0 | OSS | Yes | CNCF graduated |
| NGINX Ingress | Apache 2.0 | OSS | Yes | K8s community ingress controller; NGINX Plus is separate commercial product |
| Traefik | MIT | OSS | Yes | Traefik Enterprise is separate |

### §4 — GitOps, IaC, config management

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| GitLab CE | MIT | OSS | Yes | GitLab EE (Premium/Ultimate) requires subscription |
| GitHub Enterprise | Proprietary | Proprietary | No (requires license) | |
| Argo CD | Apache 2.0 | OSS | Yes | CNCF graduated |
| Flux | Apache 2.0 | OSS | Yes | CNCF graduated |
| Terraform | BSL 1.1 | BSL | Yes (internal) | Cannot offer as competitive hosted service |
| OpenTofu | MPL 2.0 | OSS-fork | Yes | LF/CNCF fork of Terraform 1.5.x. Drop-in replacement. MPL 2.0, no commercial restrictions. |
| Ansible (core) | GPL 3.0 | OSS | Yes | ansible-core is GPL; Ansible Automation Platform (AAP/Tower) is proprietary Red Hat product |
| Packer | BSL 1.1 | BSL | Yes (internal) | Same BSL as other HashiCorp products |

### §5 — Observability + forensics

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Prometheus | Apache 2.0 | OSS | Yes | CNCF graduated |
| Alertmanager | Apache 2.0 | OSS | Yes | |
| Thanos | Apache 2.0 | OSS | Yes | CNCF incubating |
| VictoriaMetrics | Apache 2.0 (single-node) / Proprietary (cluster enterprise) | Open-core | Single-node: Yes. Cluster enterprise features: require license. | Community cluster version also Apache 2.0; enterprise adds downsampling, multi-tenant auth, etc. |
| Grafana | AGPL 3.0 | OSS | Yes (self-hosted) | Grafana Enterprise / Cloud is proprietary. Self-hosted AGPL is fine for internal dashboards. |
| OpenTelemetry | Apache 2.0 | OSS | Yes | CNCF incubating |
| Loki | AGPL 3.0 | OSS | Yes (self-hosted) | Same model as Grafana |
| Tempo | AGPL 3.0 | OSS | Yes (self-hosted) | Same model as Grafana |
| Elasticsearch | SSPL 1.0 + Elastic License 2.0 | Non-OSS | Yes (internal, non-SaaS) | Not OSI-approved. ELv2 permits internal use but not offering as managed service. |
| OpenSearch | Apache 2.0 | OSS | Yes | AWS-driven fork from pre-SSPL Elasticsearch |
| Fluent Bit | Apache 2.0 | OSS | Yes | CNCF graduated |
| Vector | MPL 2.0 | OSS | Yes | |
| Checkmk Raw | GPL 2.0 | OSS | Yes | Raw Edition is fully OSS. Enterprise/Cloud/MSP editions are proprietary. |
| Wazuh | GPL 2.0 | OSS | Yes | |
| auditd | GPL 2.0 | OSS | Yes | Part of Linux audit framework |
| chrony | GPL 2.0 | OSS | Yes | |
| Falco | Apache 2.0 | OSS | Yes | CNCF graduated |

### §6 — Security engineering (runtime)

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| SELinux | GPL 2.0 | OSS | Yes | |
| AppArmor | GPL 2.0 | OSS | Yes | |
| OPA | Apache 2.0 | OSS | Yes | CNCF graduated |
| conftest | Apache 2.0 | OSS | Yes | |

### §7 — Storage, backup, DR

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| ZFS (OpenZFS) | CDDL 1.0 | OSS | Yes | GPL-incompatible but legally usable as loadable kernel module on Linux |
| Ceph | LGPL 2.1 / 3.0 | OSS | Yes | |
| restic | BSD 2-Clause | OSS | Yes | |
| borg | BSD 3-Clause | OSS | Yes | |
| Velero | Apache 2.0 | OSS | Yes | |
| pgBackRest | MIT | OSS | Yes | |

### §8 — Data and integration services

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| PostgreSQL | PostgreSQL License (permissive) | OSS | Yes | |
| Redis | RSALv2 + SSPLv1 (post-7.4) | Non-OSS | Yes (internal) | Since Redis 7.4: dual RSALv2/SSPLv1. Cannot offer as managed service. |
| Valkey | BSD 3-Clause | OSS-fork | Yes | LF fork of Redis 7.2.4 (last BSD release). Drop-in replacement. |
| NATS | Apache 2.0 | OSS | Yes | CNCF incubating |
| RabbitMQ | MPL 2.0 | OSS | Yes | |
| Kafka | Apache 2.0 | OSS | Yes | |
| OpenSearch | Apache 2.0 | OSS | Yes | (repeated from §5) |

### §9 — HPC / GPU

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Slurm | GPL 2.0+ | OSS | Yes | SchedMD offers commercial support separately |
| NVIDIA CUDA/NCCL | Proprietary (EULA) | Proprietary | Yes (free-of-charge, not OSS) | Free to use but proprietary; cannot redistribute modified versions |
| NVIDIA DCGM | Apache 2.0 | OSS | Yes | |
| ROCm | MIT / Apache 2.0 (varies by component) | OSS | Yes | |
| Apptainer | BSD 3-Clause | OSS | Yes | LF project |

### §10 — AI / LLMOps

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| MLflow | Apache 2.0 | OSS | Yes | |
| vLLM | Apache 2.0 | OSS | Yes | |
| TGI | Apache 2.0 | OSS | Yes | HuggingFace project |
| Ollama | MIT | OSS | Yes | |
| Qdrant | Apache 2.0 | OSS | Yes | Self-hosted is fully OSS. Qdrant Cloud is a paid managed service. |
| OpenSearch k-NN | Apache 2.0 | OSS | Yes | |
| DVC | Apache 2.0 | OSS | Yes | |

### §12 — Assurance tooling

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| TLA+ | MIT | OSS | Yes | |
| Alloy | MIT | OSS | Yes | |
| MinIO | AGPL 3.0 | OSS | Yes (self-hosted) | AGPL applies to MinIO server; commercial license available for OEM/SaaS |

### §13 — Operator workstation

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| VS Code | MIT (source) / Proprietary (Microsoft binary) | Mixed | Yes | VSCodium is the pure MIT build |
| VSCodium | MIT | OSS | Yes | |
| Neovim | Apache 2.0 | OSS | Yes | |
| JetBrains IDEs | Proprietary | Proprietary | Community editions free; Professional requires license | |
| Obsidian | Proprietary | Proprietary | Free for personal; commercial use requires license | |
| draw.io / diagrams.net | Apache 2.0 | OSS | Yes | |
| Bitwarden | AGPL 3.0 (server) / GPL 3.0 (clients) | OSS | Yes (self-hosted) | Bitwarden cloud is a paid service; self-host is OSS |

### §15 — API management (new in validation pass)

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Kong (OSS) | Apache 2.0 | OSS | Yes | Kong Enterprise is separate commercial product |
| Coraza WAF | Apache 2.0 | OSS | Yes | ModSecurity replacement |
| LiteLLM Proxy | MIT | OSS | Yes | |

### §16–§17 — AI workload governance (new in validation pass)

| Component | License | Category | Free for internal use? | Notes |
|-----------|---------|----------|----------------------|-------|
| Flipt | Apache 2.0 | OSS | Yes | Feature flag service for kill-switch |
| Unleash | Apache 2.0 (OSS) | OSS | Yes | Alternative to Flipt; Unleash Enterprise is separate |
| Gitleaks | MIT | OSS | Yes | Secret scanning |

---

## Summary: components with license risk flags

| Component | License | Risk | OSS alternative | Action needed |
|-----------|---------|------|-----------------|---------------|
| Vault (HashiCorp) | BSL 1.1 | Low (internal use OK) | OpenBao (MPL 2.0) | Evaluate OpenBao readiness; missing DR replication and Sentinel |
| Terraform | BSL 1.1 | Low (internal use OK) | OpenTofu (MPL 2.0) | Drop-in replacement; CNCF sandbox; evaluate for new projects |
| Packer | BSL 1.1 | Low (internal use OK) | No direct fork | Acceptable for now; container builds may substitute |
| Elasticsearch | SSPL + ELv2 | Medium (non-OSI) | OpenSearch (Apache 2.0) | Already in BOM as primary; Elasticsearch only if legacy |
| Redis (≥7.4) | RSALv2 + SSPLv1 | Medium (non-OSI) | Valkey (BSD 3-Clause) | Evaluate Valkey for new deployments |
| NVIDIA CUDA/NCCL | Proprietary EULA | Low (free-of-charge) | ROCm (for AMD hardware) | No action unless hardware changes |
| Grafana / Loki / Tempo | AGPL 3.0 | Low (self-hosted OK) | — | AGPL is OSI-approved; no issue for internal deployment |
| VictoriaMetrics (enterprise) | Proprietary | Medium | VM community (Apache 2.0) or Thanos | Use community edition; evaluate if enterprise features needed |
| OpenShift (RHOCP) | Proprietary | Medium | OKD (Apache 2.0) or upstream K8s | OKD for OSS; RHOCP if support contract justified |
| Obsidian | Proprietary | Low | Logseq, Joplin, plain Markdown | T3 convenience; no operational dependency |
| JetBrains IDEs | Proprietary | Low | VS Code / Neovim | T2 preference; Community editions are free |

---

## Key findings

1. **The core stack is overwhelmingly OSS.** ~85% of components are under permissive or copyleft OSI-approved licenses with zero restrictions on internal use. [I] {90}

2. **Three HashiCorp products carry BSL risk.** Vault, Terraform, and Packer are all BSL 1.1. All three have OSS alternatives (OpenBao, OpenTofu, container builds). Internal use is explicitly permitted under BSL, but the license introduces strategic uncertainty. [F] based on HashiCorp's own FAQ.

3. **Redis relicensed in 2024.** Versions ≥7.4 are dual RSALv2/SSPLv1 — not OSI-approved. Valkey (LF fork, BSD 3-Clause) is the clean OSS alternative if you need guaranteed open-source. [F]

4. **Grafana stack is AGPL.** AGPL is OSI-approved open-source. Self-hosted internal use has no compliance burden. Only becomes an issue if you offer Grafana as a service to third parties. [F]

5. **NVIDIA CUDA is free-of-charge but proprietary.** This is an unavoidable dependency on NVIDIA hardware. ROCm is the OSS alternative on AMD. No action unless you switch GPU vendor. [F]

6. **Qdrant is fully Apache 2.0.** The managed cloud service (Qdrant Cloud) is paid, but the self-hosted engine is unrestricted OSS. No license risk for your current Open WebUI usage. [F]

---

*All license claims verified via project repositories and official announcements as of 2026-03-05. Volatile: licenses can change — monitor for relicensing announcements, especially for VC-funded single-vendor projects.*
