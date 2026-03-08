# POL-09: Data Classification and Handling Policy

**Version:** 1.0 DRAFT
**Owner:** CISO + DPO
**Approved by:** [Board / Executive management — name and date]
**Review cycle:** Annual
**Classification:** Internal

## Purpose

Define the data classification scheme and handling requirements to protect information according to its sensitivity and regulatory obligations.

## Scope

All data processed, stored, or transmitted by the organisation, including personal data subject to GDPR.

## Policy statements

The organisation shall classify and handle data in accordance with the following scheme.

## Classification levels

| Level | Definition | Examples |
|-------|-----------|---------|
| Public | No restriction; loss causes no harm | Published docs, marketing |
| Internal | Organisation-internal; loss causes minor harm | Internal comms, meeting notes |
| Confidential | Restricted; loss causes significant harm | Financial data, contracts, system configs |
| Restricted | Highly restricted; loss causes severe harm | Personal data (special category), secrets, keys, credentials |

## Handling rules per classification

| Control | Internal | Confidential | Restricted |
|---------|----------|-------------|------------|
| Encryption at rest | Recommended | Required | Required (Vault Transit or ZFS encryption) |
| Encryption in transit | Required (TLS) | Required (TLS 1.2+) | Required (mTLS) |
| Access control | RBAC | RBAC + need-to-know | RBAC + need-to-know + approval |
| Logging | Standard | Enhanced (access logged) | Full audit (all operations logged) |
| Backup encryption | Required | Required | Required |
| Disposal | Standard delete | Secure delete | Crypto-erase + documented destruction |

## Personal data (GDPR overlay)

- All personal data classified Confidential minimum
- Special category data (Art 9): classified Restricted
- ROPA maintained per GDPR Art 30: `registers/ropa.md`
- DPIA required for high-risk processing (Art 35): template at `templates/dpia/`
- Data minimisation applied at design stage (Art 25)
- Log retention vs. minimisation: document legal basis per log category (Art 6(1)(c) for NIS2 obligations; Art 6(1)(f) for legitimate interest)

## Asset inventory

Maintained in `registers/asset-inventory.md`. Each system: name, owner, data classification, data types, backup status, retention period.

## Roles and responsibilities

- **CISO + DPO:** Define classification scheme; oversee handling compliance.
- **Data owners:** Classify data assets; approve access.
- **IT operations:** Implement technical controls per classification level.
- **All personnel:** Handle data according to its classification; report misclassification.

## Cross-references

| Requirement | Source |
|-------------|--------|
| NIS2 Art 21.2(i) | NIS2 Directive |
| ISO 27001:2022 A.5.12, A.5.13 | ISO 27001 |
| SCF DCL-01 | Secure Controls Framework |
| GDPR Art 5(1)(c), 5(1)(f), 25, 30 | GDPR |
| DSG § 50 | Austrian DSG |

## Review and approval

| Date | Version | Approved by | Signature |
|------|---------|-------------|-----------|
| YYYY-MM-DD | 1.0 | [Name, Title] | [Signature] |
