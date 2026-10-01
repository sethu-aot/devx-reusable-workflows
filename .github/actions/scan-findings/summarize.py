#!/usr/bin/env python3
"""Summarize a SARIF report: counts by severity, a run-summary table, a gate.

Severity of each result, in order of preference:
  1. the scanner's own label: Trivy's severity tag on the rule, or Grype's
     "<severity> vulnerability" in the rule's short description;
  2. the `security-severity` CVSS score: >= 9 critical, >= 7 high, >= 4
     medium, > 0 low;
  3. the SARIF level, as Semgrep emits it: error -> high, warning -> medium,
     note/none -> low.

The gate fails only for severities listed in FAIL_ON. Anything else found is a
warning, so a scanner can report everything without blocking the pipeline.
"""
from __future__ import annotations

import collections
import json
import os
import re
import sys

ORDER = ["critical", "high", "medium", "low"]
LEVEL = {"error": "high", "warning": "medium", "note": "low", "none": "low"}
TOP = 15


def bucket(score: object) -> str | None:
    try:
        v = float(score)
    except (TypeError, ValueError):
        return None
    if v >= 9:
        return "critical"
    if v >= 7:
        return "high"
    if v >= 4:
        return "medium"
    if v > 0:
        return "low"
    return None


LABELED = re.compile(r"\b(critical|high|medium|low|negligible)\s+vulnerability\b", re.I)


def severity(result: dict, rule: dict) -> str:
    """The scanner's own severity label first; a CVSS score overstates them
    (Grype scores CVE-2005-2541 9.8 while rating it low for Debian's tar)."""
    props = rule.get("properties") or {}
    # Trivy tags each rule with its severity.
    for tag in props.get("tags") or []:
        t = str(tag).lower()
        if t in ORDER:
            return t
    # Grype: "CVE-2023-50387 high vulnerability for libsystemd0 package".
    m = LABELED.search((rule.get("shortDescription") or {}).get("text") or "")
    if m:
        t = m.group(1).lower()
        return "low" if t == "negligible" else t
    for p in ((result.get("properties") or {}), props):
        s = bucket(p.get("security-severity"))
        if s:
            return s
    level = result.get("level") or (rule.get("defaultConfiguration") or {}).get("level") or "warning"
    return LEVEL.get(level, "medium")


def where(result: dict) -> str:
    for loc in result.get("locations") or []:
        phys = loc.get("physicalLocation") or {}
        uri = (phys.get("artifactLocation") or {}).get("uri") or ""
        line = (phys.get("region") or {}).get("startLine")
        if uri:
            return f"{uri}:{line}" if line else uri
    return ""


def text(result: dict, rule: dict) -> str:
    msg = (result.get("message") or {}).get("text") or ""
    short = (rule.get("shortDescription") or {}).get("text") or ""
    s = (short or msg).replace("\n", " ").replace("|", "\\|").strip()
    return s[:140] + ("…" if len(s) > 140 else "")


def output(name: str, value: object) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as f:
        f.write(f"{name}={value}\n")


def main() -> int:
    path = os.environ["SARIF_FILE"]
    tool = os.environ.get("TOOL") or "Scan"
    component = os.environ.get("COMPONENT") or ""
    fail_on = {s.strip().lower() for s in (os.environ.get("FAIL_ON") or "").split(",") if s.strip()}
    title = f"{tool}: {component}" if component else tool

    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        print(f"::error::{title}: no report at {path}; the scan did not complete.")
        output("status", "error")
        return 1
    try:
        sarif = json.load(open(path, encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"::error::{title}: {path} is not valid SARIF ({exc}).")
        output("status", "error")
        return 1

    counts: collections.Counter = collections.Counter()
    top: list[tuple[int, str, str, str, str]] = []
    for run in sarif.get("runs") or []:
        rules = {r.get("id"): r for r in ((run.get("tool") or {}).get("driver") or {}).get("rules") or []}
        for res in run.get("results") or []:
            rule = rules.get(res.get("ruleId"), {})
            sev = severity(res, rule)
            counts[sev] += 1
            if sev in ("critical", "high"):
                top.append((ORDER.index(sev), sev, res.get("ruleId") or "", text(res, rule), where(res)))

    total = sum(counts[s] for s in ORDER)
    blocking = [s for s in ORDER if s in fail_on and counts[s]]
    if blocking:
        status = "fail"
    elif total:
        status = "warn"
    else:
        status = "clean"

    for s in ORDER:
        output(s, counts[s])
    output("total", total)
    output("status", status)

    gate = ", ".join(sorted(fail_on, key=ORDER.index)) if fail_on else "report only"
    icon = {"fail": "❌", "warn": "⚠️", "clean": "✅"}[status]
    lines = [
        f"### {icon} {title}",
        "",
        "| Critical | High | Medium | Low | Total | Fails on |",
        "|---:|---:|---:|---:|---:|---|",
        f"| {counts['critical']} | {counts['high']} | {counts['medium']} | {counts['low']} | {total} | {gate} |",
        "",
    ]
    if top:
        top.sort()
        lines += [f"<details><summary>Critical and high findings ({len(top)}; first {min(TOP, len(top))})</summary>", "",
                  "| Severity | Rule | Finding | Where |", "|---|---|---|---|"]
        lines += [f"| {sev} | `{rid}` | {msg} | `{loc}` |" for _, sev, rid, msg, loc in top[:TOP]]
        lines += ["", "</details>", ""]
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    summary = ", ".join(f"{counts[s]} {s}" for s in ORDER)
    if status == "fail":
        print(f"::error::{title}: {summary}. Blocking on {', '.join(blocking)}.")
        return 1
    if status == "warn":
        hint = " (critical/high would block once fail_on is set)" if counts["critical"] or counts["high"] else ""
        print(f"::warning::{title}: {summary}{hint}.")
    else:
        print(f"{title}: no findings.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
