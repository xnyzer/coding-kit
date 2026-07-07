#!/usr/bin/env python3
"""Kit validation: file syntax, plugin/marketplace/skill contracts, privacy lint.

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

# The kit ships no placeholder tokens — any double-braced UPPERCASE token is a
# mistake. GitHub Actions' github.* expressions are lowercase and never match.
PLACEHOLDER_RE = re.compile(r"\{\{\s*([A-Z][A-Z0-9_]*)\s*\}\}")

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


def check_syntax(path: Path, text: str, findings: list[str]) -> None:
    rel = path.relative_to(REPO_ROOT)
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


def check_privacy(path: Path, text: str, findings: list[str]) -> None:
    rel = path.relative_to(REPO_ROOT)
    for match in PLACEHOLDER_RE.finditer(text):
        findings.append(f"{rel}: stray placeholder {match.group(0)!r} — the kit ships none")
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


def parse_frontmatter(path: Path, findings: list[str]) -> dict | None:
    text = path.read_text(encoding="utf-8")
    rel = path.relative_to(REPO_ROOT)
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
                findings.append(f"{plugin_path.relative_to(REPO_ROOT)}: missing field '{field}'")
    except (OSError, json.JSONDecodeError):
        findings.append("plugins/coding-kit/.claude-plugin/plugin.json: missing or unparseable")

    # skills: SKILL.md per directory, frontmatter name matches directory
    skills_dir = PLUGIN_ROOT / "skills"
    if skills_dir.is_dir():
        for skill_dir in sorted(p for p in skills_dir.iterdir() if p.is_dir()):
            skill_md = skill_dir / "SKILL.md"
            rel = skill_md.relative_to(REPO_ROOT)
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
        rel = hooks_path.relative_to(REPO_ROOT)
        try:
            hooks = json.loads(hooks_path.read_text(encoding="utf-8"))
            for event in hooks.get("hooks", {}):
                if event not in KNOWN_HOOK_EVENTS:
                    findings.append(f"{rel}: unknown hook event '{event}'")
        except json.JSONDecodeError:
            pass  # already reported by check_syntax
        for script in sorted((PLUGIN_ROOT / "hooks").glob("*.sh")):
            if not os.access(script, os.X_OK):
                findings.append(
                    f"{script.relative_to(REPO_ROOT)}: not executable (chmod +x)"
                )

    for name in MUST_BE_EXECUTABLE:
        path = REPO_ROOT / name
        if path.is_file() and not os.access(path, os.X_OK):
            findings.append(f"{name}: not executable (chmod +x)")


def main() -> int:
    findings: list[str] = []
    for path in iter_files():
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue  # binary file
        check_syntax(path, text, findings)
        check_privacy(path, text, findings)
    check_plugin_contracts(findings)

    if findings:
        print(f"validate: {len(findings)} finding(s):")
        for finding in findings:
            print(f"  - {finding}")
        return 1
    print("validate: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
