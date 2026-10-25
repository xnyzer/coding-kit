#!/usr/bin/env python3
"""Repo validation: file syntax, plugin/marketplace/skill contracts, privacy lint, and
the bundled template (placeholder registry, paired fragment/section markers, the
standards-fragment catalog, detection signals, and the contract between skills and
MANIFEST).

Run via `just check` (uv provides PyYAML). Exits non-zero on any finding.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
PLUGIN_ROOT = REPO_ROOT / "plugins" / "coding-kit"
TEMPLATE_ROOT = PLUGIN_ROOT / "template"
MANIFEST_PATH = TEMPLATE_ROOT / "MANIFEST.md"
CATALOG_DIR = TEMPLATE_ROOT / "modules" / "standards"

SKIP_DIRS = {".git", "node_modules", ".venv", "private"}
SKIP_FILES = {"mise.lock"}

KNOWN_HOOK_EVENTS = {
    "PreToolUse",
    "PostToolUse",
    "UserPromptSubmit",
    "Notification",
    "Stop",
    "SubagentStop",
    "SessionStart",
    "SessionEnd",
    "PreCompact",
}

# Placeholders are UPPERCASE tokens in double braces; GitHub Actions' github.*
# expressions are lowercase and never match. The registry lives in the template
# MANIFEST (## Placeholders). Template content and Markdown docs (skills, changelog,
# progress) may use or name registered tokens; every other file ships none.
PLACEHOLDER_RE = re.compile(r"\{\{\s*([A-Z][A-Z0-9_]*)\s*\}\}")
PLACEHOLDER_SECTION_RE = re.compile(r"^## Placeholders[ \t]*$(.*?)(?=^## |\Z)", re.M | re.S)
PLACEHOLDER_ROW_RE = re.compile(r"^\|\s*`\{\{([A-Z][A-Z0-9_]*)\}\}`\s*\|", re.M)

ABS_PATH_RE = re.compile(r"/(?:Users|home)/[A-Za-z0-9_.-]+")
IPV4_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")
ALLOWED_IPS = {"0.0.0.0", "127.0.0.1", "255.255.255.255"}
ALLOWED_IP_PREFIXES = ("192.0.2.", "198.51.100.", "203.0.113.")  # RFC 5737 doc ranges
# Last label must be alphabetic — keeps version pins like tool@1.2.3 from matching.
EMAIL_RE = re.compile(r"\b[\w.+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}\b")
ALLOWED_EMAIL_DOMAINS = (
    "users.noreply.github.com",
    "anthropic.com",
    "example.com",
    "example.org",
)

# Private name blocklist: gitignored, so absent in CI — the check silently skips there.
# One term per line; `#` starts a comment. The file itself is never scanned (private/ is
# in SKIP_DIRS), so listed terms never leak through validator output in CI.
BLOCKLIST_FILE = REPO_ROOT / "private" / "blocklist.txt"

# Real fragment/section markers use lowercase-kebab names; documentation placeholders
# (`fragment:NAME`, `section:<name>`) are uppercase or bracketed and never match.
PAIRED_MARKER_RE = re.compile(r"<!--\s*(/?)(fragment|section):([a-z0-9][a-z0-9-]*)\s*-->")
STANDARDS_DECL_RE = re.compile(r"Standards fragments:(.*)")
CATALOG_SECTION_RE = re.compile(r"^## Catalog[ \t]*$(.*?)(?=^## |\Z)", re.MULTILINE | re.DOTALL)
CATALOG_ROW_RE = re.compile(r"^\|\s*`([a-z0-9][a-z0-9-]*)`\s*\|", re.MULTILINE)

# Contract between the skills and the bundled template (MANIFEST.md).
MANIFEST_FORMAT_RE = re.compile(r"^`manifest-format: (\d+)`", re.MULTILINE)
SKILL_FORMAT_CLAIM_RE = re.compile(r"kann\s+Format\s+`(\d+)`")
CORE_ROW_RE = re.compile(r"^\|\s*`(core/[^`]+)`\s*\|\s*(`[^`]+`|same path)\s*\|", re.MULTILINE)
SEED_ROW_RE = re.compile(r"^\|\s*`(core/[^`]+)`\s*\|(.*)\|[ \t]*$", re.MULTILINE)
SECTION_NAME_RE = re.compile(r"`([a-z0-9][a-z0-9-]*)`")
OPTIONAL_USED_RE = re.compile(r"template:optional:NAME[^\n]*?\(used:([^)]*)\)")
OPTIONAL_BLOCK_RE = re.compile(r"<!--\s*template:optional:([a-z0-9][a-z0-9-]*)\s*-->")
OPTIONAL_NAMED_RE = re.compile(r"template:optional:([a-z0-9][a-z0-9-]*)")
REMOVED_ROW_RE = re.compile(
    r"^\|\s*(\d+(?:\.\d+)*)\s*\|\s*`([^`]+)`\s*\|\s*(`[^`]+`|removed)\s*\|\s*([^|]*?)\s*\|",
    re.MULTILINE,
)
# Module contract rows with a target file, and the per-file policy table of a MODULE.md.
MODULE_PART_ROW_RE = re.compile(r"^\|\s*`([^`]+)`\s*\|\s*`[^`]+`\s*\|", re.MULTILINE)
FILE_POLICY_ROW_RE = re.compile(r"^\|([^|]*)\|([^|]*)\|", re.MULTILINE)
BACKTICKED_RE = re.compile(r"`([^`]+)`")
FILE_POLICY_WORDS = {"managed", "seed"}
# Detection signals (MANIFEST § Detection): the signal types come from its table; full
# modules declare theirs on a `Signals:` line, catalog fragments in the trigger column.
SIGNAL_TYPE_ROW_RE = re.compile(r"^\|\s*`([a-z]+):[A-Z]+`\s*\|", re.MULTILINE)
SIGNAL_RE = re.compile(r"^([a-z]+):(\S+)$")
SIGNALS_LINE_RE = re.compile(r"^\**Signals:\**(.*)$", re.MULTILINE)
CHARACTERISTIC_MARK = "*characteristic:*"
MODULES_README = TEMPLATE_ROOT / "modules" / "README.md"
MODULE_STATUS_ROW_RE = re.compile(r"^\|\s*`([a-z0-9][a-z0-9-]*)`\s*\|\s*([a-z]*)", re.MULTILINE)
MODULE_STATUSES = {"full", "stub"}
SCRIPT_SIGNAL_TYPES_RE = re.compile(r"^SIGNAL_TYPES='([a-z ]*)'", re.MULTILINE)
# Deterministic helpers shipped with the plugin (POSIX sh, called with `sh <path>`).
PLUGIN_SCRIPTS_DIR = PLUGIN_ROOT / "scripts"
TEMPLATE_SYNC = PLUGIN_SCRIPTS_DIR / "template-sync.sh"
# Base snapshot and deviation registry (MANIFEST format 2): the tables template-sync.sh and
# the skills read, and the attribute that collapses the snapshot in diffs.
REGISTRY_TEMPLATE = TEMPLATE_ROOT / "core" / ".claude" / "convention-overrides.md"
REGISTRY_TABLES = (
    ("Files", "| Path | Kind | Reason | Since |"),
    ("Rules", "| Rule | Deviation | Reason | Since |"),
)
GITATTRIBUTES_TEMPLATE = TEMPLATE_ROOT / "core" / ".gitattributes"
SNAPSHOT_ATTRIBUTE_RE = re.compile(r"^\.claude/template-base/\*\*\s.*linguist-generated", re.M)
# `${CLAUDE_PLUGIN_ROOT}/<path>` as written in skill text (substituted at load time).
PLUGIN_ROOT_VAR = "${CLAUDE_PLUGIN_ROOT}"
PLUGIN_PATH_RE = re.compile(re.escape(PLUGIN_ROOT_VAR) + r"/([^\s`'\"),;]+)")

MUST_BE_EXECUTABLE = ("install.sh",)


def iter_files() -> list[Path]:
    files = []
    for path in sorted(REPO_ROOT.rglob("*")):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.relative_to(REPO_ROOT).parts):
            continue
        if path.name in SKIP_FILES:
            continue
        files.append(path)
    return files


def display_path(path: Path) -> Path:
    """Repo-relative path for findings; absolute for paths outside the repo."""
    try:
        return path.relative_to(REPO_ROOT)
    except ValueError:
        return path


def in_template(path: Path) -> bool:
    return path.is_relative_to(TEMPLATE_ROOT)


def check_syntax(path: Path, text: str, findings: list[str]) -> None:
    rel = display_path(path)
    if path.suffix == ".json":
        try:
            json.loads(text)
        except json.JSONDecodeError as exc:
            findings.append(f"{rel}: invalid JSON — {exc}")
    elif path.suffix in {".yml", ".yaml"}:
        try:
            list(yaml.safe_load_all(text))
        except yaml.YAMLError as exc:
            findings.append(f"{rel}: invalid YAML — {exc}")
    elif path.suffix == ".toml":
        try:
            tomllib.loads(text)
        except tomllib.TOMLDecodeError as exc:
            findings.append(f"{rel}: invalid TOML — {exc}")


def load_placeholder_registry(findings: list[str]) -> set[str]:
    """Registered placeholder tokens from the template MANIFEST (## Placeholders)."""
    if not TEMPLATE_ROOT.is_dir():
        return set()
    rel = display_path(MANIFEST_PATH)
    if not MANIFEST_PATH.is_file():
        findings.append(f"{rel}: missing — the placeholder registry lives there")
        return set()
    section = PLACEHOLDER_SECTION_RE.search(MANIFEST_PATH.read_text(encoding="utf-8"))
    tokens = set(PLACEHOLDER_ROW_RE.findall(section.group(1))) if section else set()
    if not tokens:
        findings.append(f"{rel}: no placeholder rows found in '## Placeholders'")
    return tokens


def check_placeholders(path: Path, text: str, findings: list[str], registry: set[str]) -> None:
    rel = display_path(path)
    may_use_registry = in_template(path) or path.suffix == ".md"
    for match in PLACEHOLDER_RE.finditer(text):
        token = match.group(1)
        if not may_use_registry:
            findings.append(
                f"{rel}: stray placeholder {match.group(0)!r} — only template content and "
                "Markdown docs may use registered placeholders"
            )
        elif token not in registry:
            findings.append(
                f"{rel}: unknown placeholder {{{{{token}}}}} — register it in "
                "plugins/coding-kit/template/MANIFEST.md (## Placeholders)"
            )


def check_privacy(path: Path, text: str, findings: list[str]) -> None:
    rel = display_path(path)
    for match in ABS_PATH_RE.finditer(text):
        findings.append(f"{rel}: absolute local path leaked — {match.group(0)!r}")
    for match in IPV4_RE.finditer(text):
        ip = match.group(0)
        if ip in ALLOWED_IPS or ip.startswith(ALLOWED_IP_PREFIXES):
            continue
        findings.append(f"{rel}: IP address leaked — {ip}")
    for match in EMAIL_RE.finditer(text):
        email = match.group(0)
        if email.endswith(ALLOWED_EMAIL_DOMAINS):
            continue
        findings.append(f"{rel}: email address leaked — {email}")


def load_blocklist() -> list[str]:
    if not BLOCKLIST_FILE.is_file():
        return []
    terms = []
    for line in BLOCKLIST_FILE.read_text(encoding="utf-8").splitlines():
        term = line.strip()
        if term and not term.startswith("#"):
            terms.append(term.lower())
    return terms


def check_blocklist(path: Path, text: str, findings: list[str], terms: list[str]) -> None:
    rel = display_path(path)
    lower = text.lower()
    for term in terms:
        if term in lower:
            findings.append(f"{rel}: blocklisted term leaked — {term!r}")


def check_paired_markers(path: Path, text: str, findings: list[str]) -> None:
    """Every `<!-- fragment:NAME -->` / `<!-- section:NAME -->` must be balanced by a
    matching close, in order; section names must be unique within a file."""
    rel = display_path(path)
    stacks: dict[str, list[str]] = {"fragment": [], "section": []}
    seen_sections: set[str] = set()
    for match in PAIRED_MARKER_RE.finditer(text):
        closing, kind, name = match.group(1), match.group(2), match.group(3)
        stack = stacks[kind]
        if not closing:
            if kind == "section":
                if name in seen_sections:
                    findings.append(f"{rel}: duplicate section marker '{name}'")
                seen_sections.add(name)
            stack.append(name)
        elif not stack:
            findings.append(f"{rel}: closing {kind} marker for '{name}' without a matching open")
        elif stack[-1] != name:
            findings.append(
                f"{rel}: {kind} marker mismatch — expected close for '{stack[-1]}', got '{name}'"
            )
        else:
            stack.pop()
    for kind, stack in stacks.items():
        for name in stack:
            findings.append(f"{rel}: {kind} '{name}' is opened but never closed")


def check_fragment_declarations(findings: list[str]) -> None:
    """Every fragment a `MODULE.md` declares must exist in the `modules/standards/` catalog."""
    if not CATALOG_DIR.is_dir():
        return
    catalog = {p.stem for p in CATALOG_DIR.glob("*.md") if p.name != "README.md"}
    for module_doc in sorted(TEMPLATE_ROOT.glob("modules/*/MODULE.md")):
        rel = display_path(module_doc)
        match = STANDARDS_DECL_RE.search(module_doc.read_text(encoding="utf-8"))
        if not match:
            continue
        head = re.split(r"\s[—–]\s", match.group(1).lstrip("*").strip())[0].strip()
        if head.lower() in ("", "(none)", "none"):
            continue
        for name in (n.strip().strip("`") for n in head.split(",")):
            if name and name.lower() != "none" and name not in catalog:
                findings.append(
                    f"{rel}: declares standards fragment '{name}' not found in modules/standards/"
                )


def check_fragment_files(files: dict[str, Path], findings: list[str]) -> None:
    """Each catalog file wraps its whole content in one `fragment:<file stem>` block —
    skills append the file verbatim, so text outside the wrapper would reach projects
    unmarked and could never be refreshed."""
    for name, path in files.items():
        rel = display_path(path)
        text = path.read_text(encoding="utf-8").strip()
        markers = [m for m in PAIRED_MARKER_RE.finditer(text) if m.group(2) == "fragment"]
        if not markers:
            findings.append(f"{rel}: not wrapped in a 'fragment:{name}' block")
            continue
        first, last = markers[0], markers[-1]
        if first.group(1) or first.start() != 0 or last.group(1) != "/" or last.end() != len(text):
            findings.append(f"{rel}: content outside the fragment wrapper")
        wrong = next((m.group(3) for m in (first, last) if m.group(3) != name), None)
        if wrong:
            findings.append(f"{rel}: wrapper is named '{wrong}', expected '{name}' (the file name)")
        if len(markers) > 2:
            findings.append(f"{rel}: nested fragment marker inside the wrapper")


def check_catalog_table(catalog_dir: Path, files: dict[str, Path], findings: list[str]) -> None:
    """The catalog table in README.md and the fragment files match in both directions."""
    readme = catalog_dir / "README.md"
    rel_readme = display_path(readme)
    if not readme.is_file():
        findings.append(f"{rel_readme}: catalog README is missing")
        return
    section = CATALOG_SECTION_RE.search(readme.read_text(encoding="utf-8"))
    if not section:
        findings.append(f"{rel_readme}: no '## Catalog' section")
        return
    rows = set(CATALOG_ROW_RE.findall(section.group(1)))
    for name in sorted(rows - files.keys()):
        findings.append(f"{rel_readme}: catalog row '{name}' has no file {name}.md")
    for name in sorted(files.keys() - rows):
        findings.append(f"{display_path(files[name])}: fragment has no row in the catalog table")


def check_catalog(catalog_dir: Path, findings: list[str]) -> None:
    """Standards-fragment catalog: file contract plus catalog/file consistency."""
    if not catalog_dir.is_dir():
        return
    files = {p.stem: p for p in sorted(catalog_dir.glob("*.md")) if p.name != "README.md"}
    check_fragment_files(files, findings)
    check_catalog_table(catalog_dir, files, findings)


def manifest_section(text: str, title: str) -> str | None:
    match = re.search(rf"^## {re.escape(title)}[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return match.group(1) if match else None


def core_target(source: str, target: str) -> str:
    """Project path of a core-managed row (`same path` = source without `core/`)."""
    return source.removeprefix("core/") if target == "same path" else target.strip("`")


def template_files(subdir: str) -> list[Path]:
    """Files under the template subdir that git tracks or would track (respects the
    template's own .gitignore files); plain directory walk outside a git checkout."""
    root = TEMPLATE_ROOT / subdir
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", str(root)],
        cwd=REPO_ROOT, capture_output=True, text=True,
    )
    if result.returncode == 0:
        paths = [REPO_ROOT / p for p in result.stdout.split("\0") if p]
    else:
        paths = [p for p in root.rglob("*") if p.name != ".DS_Store"]
    return sorted(p for p in paths if p.is_file())


def check_manifest_format(text: str, skills: list[Path], findings: list[str]) -> None:
    """The format MANIFEST declares is the one the skills say they support."""
    fmt = MANIFEST_FORMAT_RE.search(text)
    claims = [
        (skill, claim.group(1))
        for skill in skills
        for claim in SKILL_FORMAT_CLAIM_RE.finditer(skill.read_text(encoding="utf-8"))
    ]
    if not fmt:
        findings.append(f"{display_path(MANIFEST_PATH)}: no '`manifest-format: N`' line")
        return
    if not claims:
        findings.append("skills: none states the manifest format it supports ('kann Format `N`')")
    for skill, claim in claims:
        if claim != fmt.group(1):
            findings.append(
                f"{display_path(skill)}: supports manifest-format {claim}, "
                f"MANIFEST has {fmt.group(1)}"
            )


def check_core_table(rows: list[tuple[str, str]], findings: list[str]) -> None:
    """Core-managed table and files under template/core/ match in both directions."""
    sources = {source for source, _ in rows}
    if not rows:
        findings.append(f"{display_path(MANIFEST_PATH)}: no rows in '## Core-managed files'")
    for source in sorted(sources):
        if not (TEMPLATE_ROOT / source).is_file():
            findings.append(
                f"{display_path(MANIFEST_PATH)}: core-managed table lists {source}, "
                "but the file is missing"
            )
    for path in template_files("core"):
        if path.relative_to(TEMPLATE_ROOT).as_posix() not in sources:
            findings.append(f"{display_path(path)}: not in the MANIFEST core-managed table")


def check_seed_inventory(text: str, sources: set[str], findings: list[str]) -> None:
    """MANIFEST § Seed sections lists exactly the section markers in each core file."""
    inventory = {
        source: set(SECTION_NAME_RE.findall(names))
        for source, names in SEED_ROW_RE.findall(manifest_section(text, "Seed sections") or "")
    }
    for path in template_files("core"):
        content = path.read_text(encoding="utf-8", errors="replace")
        markers = {
            m.group(3)
            for m in PAIRED_MARKER_RE.finditer(content)
            if m.group(2) == "section" and not m.group(1)
        }
        listed = inventory.get(path.relative_to(TEMPLATE_ROOT).as_posix(), set())
        rel = display_path(path)
        for name in sorted(listed - markers):
            findings.append(f"{rel}: seed section '{name}' listed in MANIFEST but not marked")
        for name in sorted(markers - listed):
            findings.append(f"{rel}: section '{name}' is not in MANIFEST § Seed sections")
    for source in sorted(inventory.keys() - sources):
        findings.append(
            f"{display_path(MANIFEST_PATH)}: seed inventory lists {source}, "
            "which is not a core-managed source"
        )


def check_removed_table(text: str, targets: set[str], findings: list[str]) -> None:
    """Rows of § Removed and renamed targets agree with the current core targets."""
    rel = display_path(MANIFEST_PATH)
    section = manifest_section(text, "Removed and renamed targets") or ""
    for version, old, new, policy in REMOVED_ROW_RE.findall(section):
        if old in targets:
            findings.append(f"{rel}: '{old}' is listed as removed/renamed in {version} "
                            "but is still a core target")
        if new != "removed" and new.strip("`") not in targets:
            findings.append(f"{rel}: '{old}' renamed to {new} in {version}, "
                            "which is not a core target")
        if not policy:
            findings.append(f"{rel}: removed/renamed row for '{old}' has no policy")


def check_optional_blocks(text: str, skills: list[Path], findings: list[str]) -> None:
    """Optional blocks: MANIFEST § Markers ('used: …'), template content and the
    `template:optional:<name>` references in skills all name the same blocks."""
    rel = display_path(MANIFEST_PATH)
    used = OPTIONAL_USED_RE.search(text)
    if not used:
        findings.append(f"{rel}: § Markers does not list the optional blocks ('(used: …)')")
    declared = set(SECTION_NAME_RE.findall(used.group(1))) if used else set()
    present = {
        name
        for path in template_files("")
        for name in OPTIONAL_BLOCK_RE.findall(path.read_text(encoding="utf-8", errors="replace"))
    }
    for name in sorted(declared - present):
        findings.append(f"{rel}: optional block '{name}' is listed as used but not in the template")
    for name in sorted(present - declared):
        findings.append(f"{rel}: optional block '{name}' is in the template but not in § Markers")
    for skill in skills:
        for name in sorted(set(OPTIONAL_NAMED_RE.findall(skill.read_text(encoding="utf-8")))):
            if name not in present:
                findings.append(
                    f"{display_path(skill)}: names template:optional:{name}, "
                    "which the template does not have"
                )


def check_module_parts_known(text: str, findings: list[str]) -> None:
    """Every module part with a target file in § Module contract is one the renderer
    (`scripts/template-sync.sh`) can apply — a new part needs its mechanics there."""
    if not TEMPLATE_SYNC.is_file():
        findings.append(f"{display_path(TEMPLATE_SYNC)}: missing — it renders the template")
        return
    script = TEMPLATE_SYNC.read_text(encoding="utf-8")
    for part in MODULE_PART_ROW_RE.findall(manifest_section(text, "Module contract") or ""):
        if f"{part})" not in script:
            findings.append(
                f"{display_path(MANIFEST_PATH)}: module part '{part}' is not handled by "
                f"{display_path(TEMPLATE_SYNC)}"
            )


def check_module_file_policies(findings: list[str]) -> None:
    """`## File policies (files/)` in each MODULE.md lists every file under `files/` once,
    by its full path, with a policy cell starting with `managed` or `seed`."""
    for module_dir in sorted(p for p in (TEMPLATE_ROOT / "modules").iterdir() if p.is_dir()):
        files_dir = module_dir / "files"
        if not files_dir.is_dir():
            continue
        module_doc = module_dir / "MODULE.md"
        rel = display_path(module_doc)
        text = module_doc.read_text(encoding="utf-8") if module_doc.is_file() else ""
        section = re.search(r"^## File policies[^\n]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
        if not section:
            findings.append(f"{rel}: no '## File policies (files/)' table, but files/ exists")
            continue
        listed: dict[str, str] = {}
        for entries, policy in FILE_POLICY_ROW_RE.findall(section.group(1)):
            names = BACKTICKED_RE.findall(entries)
            if not names:
                continue  # header or separator row
            first = re.match(r"\s*([a-z]+)", policy)
            word = first.group(1) if first else ""
            for name in names:
                if name in listed:
                    findings.append(f"{rel}: '{name}' is listed twice in § File policies")
                listed[name] = word
                if word not in FILE_POLICY_WORDS:
                    findings.append(
                        f"{rel}: policy of '{name}' must start with managed or seed, not '{word}'"
                    )
        present = {p.relative_to(files_dir).as_posix() for p in template_files(
            files_dir.relative_to(TEMPLATE_ROOT).as_posix())}
        for name in sorted(present - listed.keys()):
            findings.append(f"{rel}: files/{name} has no row (full path) in § File policies")
        for name in sorted(listed.keys() - present):
            findings.append(f"{rel}: § File policies lists '{name}', which is not under files/")


def check_signals(where: str, signals: list[str], types: set[str], findings: list[str]) -> None:
    """Each signal is `type:value` with a type from MANIFEST § Detection."""
    for signal in signals:
        match = SIGNAL_RE.match(signal)
        if not match:
            findings.append(f"{where}: '{signal}' is not a typed signal (type:value)")
        elif match.group(1) not in types:
            findings.append(f"{where}: unknown signal type '{match.group(1)}' in '{signal}'")


def check_catalog_signals(types: set[str], findings: list[str]) -> None:
    """Every catalog row triggers by typed signals in backticks or by one characteristic —
    `detect` reads the signals, so an untyped or unquoted trigger would never match."""
    readme = CATALOG_DIR / "README.md"
    if not readme.is_file():
        return  # reported by check_catalog_table
    rel = display_path(readme)
    section = CATALOG_SECTION_RE.search(readme.read_text(encoding="utf-8"))
    for line in (section.group(1) if section else "").splitlines():
        if not CATALOG_ROW_RE.match(line):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        name, trigger = cells[0].strip("`"), cells[-1]
        where = f"{rel}: catalog row '{name}'"
        if CHARACTERISTIC_MARK in trigger:
            if BACKTICKED_RE.search(trigger):
                findings.append(f"{where}: mixes signals with a characteristic trigger")
            continue
        signals = BACKTICKED_RE.findall(trigger)
        if not signals:
            findings.append(f"{where}: no signal and no characteristic trigger")
        if BACKTICKED_RE.sub("", trigger).replace(",", "").strip():
            findings.append(f"{where}: trigger text outside backticks (signals only)")
        check_signals(where, signals, types, findings)


def check_module_signals(types: set[str], findings: list[str]) -> None:
    """A full module (status in modules/README.md) declares its signals on one `Signals:`
    line, `(none)` allowed; a stub carries none, so detection never proposes it."""
    rel_readme = display_path(MODULES_README)
    if not MODULES_README.is_file():
        findings.append(f"{rel_readme}: module overview is missing")
        return
    statuses = dict(MODULE_STATUS_ROW_RE.findall(MODULES_README.read_text(encoding="utf-8")))
    for module_doc in sorted(TEMPLATE_ROOT.glob("modules/*/MODULE.md")):
        name = module_doc.parent.name
        rel = display_path(module_doc)
        status = statuses.get(name)
        if status not in MODULE_STATUSES:
            findings.append(f"{rel_readme}: module '{name}' needs a row with status full or stub")
            continue
        match = SIGNALS_LINE_RE.search(module_doc.read_text(encoding="utf-8"))
        if status == "stub":
            if match:
                findings.append(f"{rel}: stub module carries a Signals: line")
            continue
        head = re.split(r"\s[—–]\s", match.group(1).strip())[0].strip() if match else ""
        if not head:
            findings.append(f"{rel}: full module has no Signals: line (MANIFEST § Detection)")
            continue
        if head.lower() in ("(none)", "none"):
            continue
        items = [item.strip() for item in head.split(",")]
        for item in items:
            if not (len(item) > 2 and item.startswith("`") and item.endswith("`")):
                findings.append(f"{rel}: signal '{item}' is not in backticks")
        check_signals(f"{rel}: Signals", [item.strip("`") for item in items], types, findings)


def check_script_signal_types(types: set[str], findings: list[str]) -> None:
    """`template-sync.sh detect` reads exactly the signal types the MANIFEST defines."""
    if not TEMPLATE_SYNC.is_file():
        return  # reported by check_module_parts_known
    match = SCRIPT_SIGNAL_TYPES_RE.search(TEMPLATE_SYNC.read_text(encoding="utf-8"))
    script_types = set(match.group(1).split()) if match else set()
    if script_types != types:
        findings.append(
            f"{display_path(TEMPLATE_SYNC)}: SIGNAL_TYPES {sorted(script_types)} differ from "
            f"MANIFEST § Detection {sorted(types)}"
        )


def check_detection(text: str, findings: list[str]) -> None:
    """MANIFEST § Detection defines the signal types; catalog, modules and the script use
    only those."""
    types = set(SIGNAL_TYPE_ROW_RE.findall(manifest_section(text, "Detection") or ""))
    if not types:
        findings.append(f"{display_path(MANIFEST_PATH)}: § Detection defines no signal types")
        return
    check_catalog_signals(types, findings)
    check_module_signals(types, findings)
    check_script_signal_types(types, findings)


def check_snapshot_contract(text: str, findings: list[str]) -> None:
    """MANIFEST declares the base snapshot and the deviation registry; the registry template
    carries both tables with the headers the script and the skills read; the template's
    .gitattributes marks the snapshot as generated."""
    rel = display_path(MANIFEST_PATH)
    for title in ("Base snapshot", "Deviation registry"):
        if manifest_section(text, title) is None:
            findings.append(f"{rel}: no '## {title}' section")
    if REGISTRY_TEMPLATE.is_file():
        registry = REGISTRY_TEMPLATE.read_text(encoding="utf-8")
        for title, header in REGISTRY_TABLES:
            section = re.search(rf"^## {title}[ \t]*$(.*?)(?=^## |\Z)", registry, re.M | re.S)
            if not section or header not in section.group(1):
                findings.append(
                    f"{display_path(REGISTRY_TEMPLATE)}: no '## {title}' table with the "
                    f"header {header!r}"
                )
    else:
        findings.append(f"{display_path(REGISTRY_TEMPLATE)}: missing")
    attributes = (
        GITATTRIBUTES_TEMPLATE.read_text(encoding="utf-8")
        if GITATTRIBUTES_TEMPLATE.is_file()
        else ""
    )
    if not SNAPSHOT_ATTRIBUTE_RE.search(attributes):
        findings.append(
            f"{display_path(GITATTRIBUTES_TEMPLATE)}: no "
            "'.claude/template-base/** linguist-generated' line"
        )


def check_plugin_scripts(findings: list[str]) -> None:
    """Plugin scripts are executable and parse as POSIX sh."""
    for script in sorted(PLUGIN_SCRIPTS_DIR.glob("*.sh")):
        rel = display_path(script)
        if not os.access(script, os.X_OK):
            findings.append(f"{rel}: not executable (chmod +x)")
        result = subprocess.run(["sh", "-n", str(script)], capture_output=True, text=True)
        if result.returncode != 0:
            findings.append(f"{rel}: sh -n failed — {result.stderr.strip()}")


def check_plugin_paths(skills: list[Path], findings: list[str]) -> None:
    """Every `${CLAUDE_PLUGIN_ROOT}/<path>` a skill names exists in the plugin."""
    for skill in skills:
        for match in PLUGIN_PATH_RE.finditer(skill.read_text(encoding="utf-8")):
            path = match.group(1).rstrip(".:")
            if any(ch in path for ch in "<*{"):
                continue
            if not (PLUGIN_ROOT / path).exists():
                findings.append(
                    f"{display_path(skill)}: names {PLUGIN_ROOT_VAR}/{path}, which does not exist"
                )


def check_template_contract(findings: list[str]) -> None:
    """Skills and template agree on the MANIFEST contract."""
    if not MANIFEST_PATH.is_file():
        return  # reported by load_placeholder_registry
    text = MANIFEST_PATH.read_text(encoding="utf-8")
    skills = sorted((PLUGIN_ROOT / "skills").glob("*/SKILL.md"))
    rows = CORE_ROW_RE.findall(manifest_section(text, "Core-managed files") or "")
    check_manifest_format(text, skills, findings)
    check_core_table(rows, findings)
    check_seed_inventory(text, {source for source, _ in rows}, findings)
    check_removed_table(text, {core_target(s, t) for s, t in rows}, findings)
    check_optional_blocks(text, skills, findings)
    check_plugin_paths(skills, findings)
    check_module_parts_known(text, findings)
    check_module_file_policies(findings)
    check_snapshot_contract(text, findings)
    check_detection(text, findings)


def parse_frontmatter(path: Path, findings: list[str]) -> dict | None:
    text = path.read_text(encoding="utf-8")
    rel = display_path(path)
    if not text.startswith("---\n"):
        findings.append(f"{rel}: missing YAML frontmatter")
        return None
    end = text.find("\n---", 4)
    if end == -1:
        findings.append(f"{rel}: unterminated YAML frontmatter")
        return None
    try:
        data = yaml.safe_load(text[4:end])
    except yaml.YAMLError as exc:
        findings.append(f"{rel}: invalid frontmatter YAML — {exc}")
        return None
    if not isinstance(data, dict):
        findings.append(f"{rel}: frontmatter is not a mapping")
        return None
    return data


def check_plugin_contracts(findings: list[str]) -> None:
    # marketplace.json: name/owner/plugins present, every relative source exists
    marketplace_path = REPO_ROOT / ".claude-plugin" / "marketplace.json"
    try:
        marketplace = json.loads(marketplace_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        findings.append(".claude-plugin/marketplace.json: missing or unparseable")
        return
    for field in ("name", "owner", "plugins"):
        if field not in marketplace:
            findings.append(f".claude-plugin/marketplace.json: missing field '{field}'")
    for entry in marketplace.get("plugins", []):
        for field in ("name", "description", "source"):
            if field not in entry:
                findings.append(
                    f".claude-plugin/marketplace.json: plugin entry missing '{field}'"
                )
        source = entry.get("source")
        if isinstance(source, str) and source.startswith("./"):
            if not (REPO_ROOT / source).is_dir():
                findings.append(
                    f".claude-plugin/marketplace.json: source '{source}' does not exist"
                )

    # plugin.json: name/version/description
    plugin_path = PLUGIN_ROOT / ".claude-plugin" / "plugin.json"
    try:
        plugin = json.loads(plugin_path.read_text(encoding="utf-8"))
        for field in ("name", "version", "description"):
            if field not in plugin:
                findings.append(f"{display_path(plugin_path)}: missing field '{field}'")
    except (OSError, json.JSONDecodeError):
        findings.append("plugins/coding-kit/.claude-plugin/plugin.json: missing or unparseable")

    # skills: SKILL.md per directory, frontmatter name matches directory
    skills_dir = PLUGIN_ROOT / "skills"
    if skills_dir.is_dir():
        for skill_dir in sorted(p for p in skills_dir.iterdir() if p.is_dir()):
            skill_md = skill_dir / "SKILL.md"
            rel = display_path(skill_md)
            if not skill_md.is_file():
                findings.append(f"{rel}: missing")
                continue
            fm = parse_frontmatter(skill_md, findings)
            if fm is None:
                continue
            for field in ("name", "description"):
                if not fm.get(field):
                    findings.append(f"{rel}: frontmatter missing '{field}'")
            if fm.get("name") and fm["name"] != skill_dir.name:
                findings.append(
                    f"{rel}: frontmatter name '{fm['name']}' != directory '{skill_dir.name}'"
                )

    # hooks.json: known event names, referenced scripts exist and are executable
    hooks_path = PLUGIN_ROOT / "hooks" / "hooks.json"
    if hooks_path.is_file():
        rel = display_path(hooks_path)
        try:
            hooks = json.loads(hooks_path.read_text(encoding="utf-8"))
            for event in hooks.get("hooks", {}):
                if event not in KNOWN_HOOK_EVENTS:
                    findings.append(f"{rel}: unknown hook event '{event}'")
        except json.JSONDecodeError:
            pass  # already reported by check_syntax
        for script in sorted((PLUGIN_ROOT / "hooks").glob("*.sh")):
            if not os.access(script, os.X_OK):
                findings.append(f"{display_path(script)}: not executable (chmod +x)")

    for name in MUST_BE_EXECUTABLE:
        path = REPO_ROOT / name
        if path.is_file() and not os.access(path, os.X_OK):
            findings.append(f"{name}: not executable (chmod +x)")

    check_plugin_scripts(findings)


def main() -> int:
    findings: list[str] = []
    registry = load_placeholder_registry(findings)
    blocklist = load_blocklist()
    for path in iter_files():
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue  # binary file
        check_syntax(path, text, findings)
        check_placeholders(path, text, findings, registry)
        check_privacy(path, text, findings)
        check_blocklist(path, text, findings, blocklist)
        if in_template(path):
            check_paired_markers(path, text, findings)
    check_plugin_contracts(findings)
    check_template_contract(findings)
    check_fragment_declarations(findings)
    check_catalog(CATALOG_DIR, findings)

    if findings:
        print(f"validate: {len(findings)} finding(s):")
        for finding in findings:
            print(f"  - {finding}")
        return 1
    print("validate: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
