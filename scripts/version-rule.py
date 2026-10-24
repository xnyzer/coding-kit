#!/usr/bin/env python3
"""Version rule: a change to plugin content needs a version bump and a CHANGELOG entry.

Plugin content is everything under plugins/coding-kit/{skills,hooks,scripts,template}/.
When a change touches it, plugin.json must carry a version above the comparison base, and
the CHANGELOG must have a `## <version>` entry for it. Several commits may share one
unreleased version: the base is the pushed state, not the previous commit. A target that
leaves the MANIFEST core-managed table also needs a row for that version in
`## Removed and renamed targets`.

  --staged        pre-commit: staged changes, base = upstream branch (fallback: HEAD)
  --since <rev>   CI: changes from <rev> to HEAD; an all-zero <rev> (new branch) skips

Run via `just version-rule …`. Exits non-zero on any finding.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys

PLUGIN = "plugins/coding-kit"
CONTENT_PREFIXES = tuple(
    f"{PLUGIN}/{part}/" for part in ("skills", "hooks", "scripts", "template")
)
PLUGIN_JSON = f"{PLUGIN}/.claude-plugin/plugin.json"
CHANGELOG = f"{PLUGIN}/CHANGELOG.md"
MANIFEST = f"{PLUGIN}/template/MANIFEST.md"
NULL_REV = re.compile(r"^0+$")
# Table rows as parsed by scripts/validate.py — keep both in sync.
CORE_ROW_RE = re.compile(r"^\|\s*`(core/[^`]+)`\s*\|\s*(`[^`]+`|same path)\s*\|", re.MULTILINE)
REMOVED_ROW_RE = re.compile(
    r"^\|\s*(\d+(?:\.\d+)*)\s*\|\s*`([^`]+)`\s*\|\s*(`[^`]+`|removed)\s*\|", re.MULTILINE
)


def git(*args: str) -> str | None:
    """Stdout of a git command, or None when it fails."""
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else None


def file_at(spec: str, path: str) -> str | None:
    """File content at a revision (`HEAD`, a SHA) or in the index (spec "")."""
    return git("show", f"{spec}:{path}")


def version_at(spec: str) -> str | None:
    text = file_at(spec, PLUGIN_JSON)
    if text is None:
        return None
    try:
        return json.loads(text).get("version")
    except json.JSONDecodeError:
        return None


def parse_version(raw: str) -> tuple[int, ...] | None:
    if not re.fullmatch(r"\d+(\.\d+)*", raw):
        return None
    return tuple(int(part) for part in raw.split("."))


def has_changelog_entry(spec: str, version: str) -> bool:
    text = file_at(spec, CHANGELOG) or ""
    return re.search(rf"^## {re.escape(version)}(\s|$)", text, re.MULTILINE) is not None


def manifest_section(text: str, title: str) -> str:
    match = re.search(rf"^## {re.escape(title)}[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return match.group(1) if match else ""


def core_targets(manifest: str) -> set[str]:
    rows = CORE_ROW_RE.findall(manifest_section(manifest, "Core-managed files"))
    return {
        source.removeprefix("core/") if target == "same path" else target.strip("`")
        for source, target in rows
    }


def check_removed_targets(base: str, current: str, version: str) -> list[str]:
    """A target that leaves the core-managed table needs a row for this version in
    MANIFEST § Removed and renamed targets — /update-conventions reads only that table."""
    old, new = file_at(base, MANIFEST), file_at(current, MANIFEST)
    if old is None or new is None:
        return []
    declared = {
        target
        for row_version, target, _ in REMOVED_ROW_RE.findall(
            manifest_section(new, "Removed and renamed targets")
        )
        if row_version == version
    }
    return [
        f"{MANIFEST}: core target '{target}' left the core-managed table — add a {version} "
        "row to '## Removed and renamed targets'"
        for target in sorted(core_targets(old) - core_targets(new) - declared)
    ]


def check(changed: list[str], base: str, current: str) -> list[str]:
    """Findings for the change set; `current` is "" (index) or "HEAD"."""
    touched = sorted(p for p in changed if p.startswith(CONTENT_PREFIXES))
    if not touched:
        return []
    findings: list[str] = []
    new_raw = version_at(current)
    new = parse_version(new_raw) if new_raw else None
    if new is None:
        return [f"{PLUGIN_JSON}: no readable semver 'version'"]
    old_raw = version_at(base)
    old = parse_version(old_raw) if old_raw else None
    if old is not None and new <= old:
        findings.append(
            f"{PLUGIN_JSON}: version {new_raw} is not above {old_raw} ({base}) — plugin "
            f"content changed (e.g. {touched[0]}), bump the version"
        )
    if not has_changelog_entry(current, new_raw):
        findings.append(f"{CHANGELOG}: no '## {new_raw}' entry for the bumped version")
    if MANIFEST in changed:
        findings.extend(check_removed_targets(base, current, new_raw))
    return findings


def changed_files(*diff_args: str) -> list[str] | None:
    out = git("diff", "--name-only", "--no-renames", *diff_args)
    return None if out is None else [line for line in out.splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--staged", action="store_true")
    mode.add_argument("--since", metavar="REV")
    args = parser.parse_args()

    if args.staged:
        if git("rev-parse", "--verify", "--quiet", "HEAD") is None:
            print("version-rule: no HEAD yet — skipped")
            return 0
        upstream = git("rev-parse", "--verify", "--quiet", "@{upstream}")
        base = upstream.strip() if upstream else "HEAD"
        changed, current = changed_files("--cached"), ""
    else:
        if NULL_REV.match(args.since):
            print("version-rule: no base revision (new branch) — skipped")
            return 0
        if git("rev-parse", "--verify", "--quiet", f"{args.since}^{{commit}}") is None:
            print(f"version-rule: base {args.since} not available (shallow clone?)")
            return 1
        base = args.since
        changed, current = changed_files(base, "HEAD"), "HEAD"

    if changed is None:
        print("version-rule: git diff failed")
        return 1
    findings = check(changed, base, current)
    if findings:
        print(f"version-rule: {len(findings)} finding(s):")
        for finding in findings:
            print(f"  - {finding}")
        return 1
    print("version-rule: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
