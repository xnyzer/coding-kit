<!-- fragment:python-lang -->
### Python

Rules for all Python code in the project, whatever toolchain runs it.

- **Type hints are mandatory** on all public functions — fix the types, don't
  `# type: ignore` (if unavoidable, use a scoped ignore with a reason).
- **Safe calls (core §8):** `subprocess` with an argument list, never `shell=True`; no
  `eval`/`exec`, `pickle`, or `yaml.load` (use `yaml.safe_load`) on untrusted data.
- **Naming:** snake_case for functions/modules, PascalCase for classes, UPPER_SNAKE for
  constants.
- **Dependencies:** pinned in a committed lock file; permissive licenses only (§8).
<!-- /fragment:python-lang -->
