#!/usr/bin/env python3
"""Repo validation: file syntax, plugin/marketplace/skill contracts, privacy lint, and
the bundled template (placeholder registry, paired fragment/section markers, the
standards-fragment catalog).

Run via `just check` (uv provides PyYAML). Exits non-zero on any finding.
"""

from __future__ import annotations

import json
import os
import re
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
