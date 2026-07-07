#!/usr/bin/env python3
"""Template validation: JSON/YAML syntax, placeholder registry, privacy lint.

Run via `just check` (uv provides PyYAML). Exits non-zero on any finding.
"""

from __future__ import annotations

import json
import re
import sys
import tomllib
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent

SKIP_DIRS = {".git", "node_modules", ".venv", "private"}
SKIP_FILES = {"mise.lock"}

# Must match the registry in MANIFEST.md (## Placeholders).
ALLOWED_PLACEHOLDERS = {
    "PROJECT_NAME",
    "PROJECT_NAME_SNAKE",
    "PROJECT_DESCRIPTION",
    "OWNER",
    "YEAR",
    "GROUP_ID",
    "CODEQL_LANGUAGES",
    "LIVING_DOC_LANGUAGE",
    "LICENSE_SPDX",
    "TEMPLATE_VERSION",
}

# Uppercase-only tokens; GitHub Actions' ${{ github.* }} is lowercase and never matches.
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


def check_placeholders(path: Path, text: str, findings: list[str]) -> None:
    rel = path.relative_to(REPO_ROOT)
    for match in PLACEHOLDER_RE.finditer(text):
        token = match.group(1)
        if token not in ALLOWED_PLACEHOLDERS:
            findings.append(
                f"{rel}: unknown placeholder {{{{{token}}}}} — register it in MANIFEST.md"
            )


def check_privacy(path: Path, text: str, findings: list[str]) -> None:
    rel = path.relative_to(REPO_ROOT)
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


def main() -> int:
    findings: list[str] = []
    for path in iter_files():
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue  # binary file
        check_syntax(path, text, findings)
        check_placeholders(path, text, findings)
        check_privacy(path, text, findings)

    if findings:
        print(f"validate: {len(findings)} finding(s):")
        for finding in findings:
            print(f"  - {finding}")
        return 1
    print("validate: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
