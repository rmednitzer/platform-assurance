#!/usr/bin/env python3
from __future__ import annotations
import datetime as dt
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "controls/catalog.yaml"
OUT_DIR = ROOT / "docs/generated"


def load_catalog() -> dict:
    return yaml.safe_load(CATALOG.read_text())


def render_control_catalog(catalog: dict) -> str:
    lines = []
    lines.append("# Generated Control Catalog\n")
    lines.append("This file is generated from `controls/catalog.yaml`. Edit the catalog, not this view.\n")
    lines.append(f"Generated: {dt.datetime.now(dt.UTC).strftime('%Y-%m-%dT%H:%M:%SZ')}\n")
    lines.append("## Control summary\n")
    lines.append("| ID | Title | Boundary | Type | Owners | Evidence artifact |")
    lines.append("|----|-------|----------|------|--------|-------------------|")
    for c in catalog["controls"]:
        lines.append(
            f"| {c['control_id']} | {c['title']} | {c['boundary']} | {c['artifact_type']} | {', '.join(c['owners'])} | {c['evidence_schema']['artifact_type']} |"
        )
    lines.append("")
    for c in catalog["controls"]:
        lines.append(f"## {c['control_id']} — {c['title']}\n")
        lines.append(f"- Status: {c['status']}")
        lines.append(f"- Artifact type: {c['artifact_type']}")
        lines.append(f"- Boundary: {c['boundary']}")
        lines.append(f"- Objective: {c['objective']}")
        lines.append(f"- Required capability: {', '.join(c['required_capability'])}")
        lines.append(f"- Approved patterns: {', '.join(c['approved_patterns'])}")
        lines.append(f"- Owners: {', '.join(c['owners'])}")
        lines.append(f"- Verification: `{c['verification_command']}`")
        lines.append(f"- Evidence artifact: `{c['evidence_schema']['artifact_type']}`")
        lines.append(f"- Required files: {', '.join(c['evidence_schema']['required_files'])}")
        lines.append(f"- Retention tier: {c['evidence_schema']['retention_tier']}")
        lines.append(f"- Exception process: {c['exception_process']}\n")
        lines.append("### Applicability")
        lines.append("| Framework | Regulatory reference | Roles | From | Until | Condition |")
        lines.append("|-----------|----------------------|-------|------|-------|-----------|")
        for app in c['applicability']:
            lines.append(
                f"| {app['framework']} | {app['regulatory_ref']} | {', '.join(app['roles'])} | {app['applicable_from']} | {app.get('applicable_until', '')} | {app.get('condition', '')} |"
            )
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_applicability(catalog: dict) -> str:
    rows = []
    for c in catalog["controls"]:
        for app in c["applicability"]:
            rows.append((app["applicable_from"], c["control_id"], c["title"], app["framework"], app["regulatory_ref"], ", ".join(app["roles"]), app.get("applicable_until", ""), app.get("condition", "")))
    rows.sort()
    lines = []
    lines.append("# Generated Applicability Matrix\n")
    lines.append("This file is generated from `controls/catalog.yaml`.\n")
    lines.append(f"Generated: {dt.datetime.now(dt.UTC).strftime('%Y-%m-%dT%H:%M:%SZ')}\n")
    lines.append("| From | Control ID | Title | Framework | Regulatory reference | Roles | Until | Condition |")
    lines.append("|------|------------|-------|-----------|----------------------|-------|-------|-----------|")
    for row in rows:
        lines.append("| {} | {} | {} | {} | {} | {} | {} | {} |".format(*row))
    lines.append("")
    lines.append("## Date-sensitive anchors\n")
    lines.append("- 2018-05-25: GDPR general application")
    lines.append("- 2024-10-17: NIS2 transposition deadline reference point for operational planning")
    lines.append("- 2026-08-02: AI Act general application for most obligations")
    lines.append("- 2026-09-11: CRA Article 14 application")
    lines.append("- 2026-10-01: Austrian NISG 2026 effective date")
    lines.append("- 2027-12-11: CRA general application")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    catalog = load_catalog()
    (OUT_DIR / "control-catalog.md").write_text(render_control_catalog(catalog))
    (OUT_DIR / "applicability-matrix.md").write_text(render_applicability(catalog))


if __name__ == "__main__":
    main()
