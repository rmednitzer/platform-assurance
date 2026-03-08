# POL-03: Access Control Policy

**Version:** 1.0 DRAFT
**Owner:** CISO
**Approved by:** [Board / Executive management — name and date]
**Review cycle:** Annual
**Classification:** Internal

## Purpose

Define the access control requirements to protect information assets through identity management, authentication, and authorisation.

## Scope

All users (human and machine), systems, and network resources within the organisation's infrastructure.

## Policy statements

The organisation shall enforce access controls based on the following principles and procedures.

## Principles

1. Least privilege: users receive minimum access necessary for their role.
2. Need-to-know: access to data based on business need, not hierarchy.
3. Separation of duties: critical functions require multiple actors.
4. Default deny: access is denied unless explicitly granted.

## Identity and authentication

- All users authenticated via Keycloak (OIDC/SAML).
- MFA mandatory for all human users (TOTP or FIDO2/WebAuthn).
- Service accounts: Vault/OpenBao dynamic credentials; short-lived leases.
- SSH: key-based only; password authentication disabled.

## Authorization model

- Application: RBAC via Keycloak roles; ABAC via OPA where needed.
- Kubernetes: RBAC; least-privilege RoleBindings per namespace.
- Infrastructure: Vault/OpenBao policies; path-based ACLs.
- Network: Cilium NetworkPolicy; default-deny ingress and egress.

## Access lifecycle

- Provisioning: HR-triggered via Keycloak; approval required for elevated roles.
- Review: quarterly access review by team managers (template: `templates/access-review/`).
- Deprovision: same-day revocation on termination; automated via HR integration.

## Privileged access

- JIT access via Vault/OpenBao dynamic credentials.
- Break-glass procedure documented and tested annually.
- All privileged sessions logged (auditd + Vault audit + K8s API audit).

## Monitoring

- Failed auth monitoring (Keycloak events → Wazuh).
- Service account usage monitoring (Vault audit → alerting).
- RBAC drift detection (monthly automated check vs. Git baseline).

## Roles and responsibilities

- **CISO:** Define access control policy; approve privileged access procedures.
- **Team managers:** Conduct quarterly access reviews; approve role assignments.
- **IT operations:** Implement technical access controls; manage Keycloak and Vault.
- **All personnel:** Use assigned credentials only; report suspicious access.

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(i), 21.2(j) | NIS2 Directive |
| ISO 27001:2022 A.5.15, A.8.2, A.8.5 | ISO 27001 |
| SCF IAC-01 | Secure Controls Framework |
| GDPR Art 25, 32 | GDPR |
| DSG § 50 | Austrian DSG |

## Review and approval

| Date | Version | Approved by | Signature |
|------|---------|-------------|-----------|
| YYYY-MM-DD | 1.0 | [Name, Title] | [Signature] |
