<!-- fragment:python -->
### Python toolchain (python module)

- **Runtime:** current stable Python via mise; `requires-python` enforces the floor.
- **uv only** for environments, dependencies, running, and building — no bare `pip`,
  no manual venv management. `uv run` is the way to execute anything project-local.
- **src layout** (`src/<package>/`) with `py.typed`; imports are absolute from the package.
- **pyright runs strict** on the type hints.
- **ruff** is the single formatter + linter (config in `pyproject.toml`); import sorting
  via the `I` rules. Zero lint findings — warnings count as errors (§1).
- **Tests: pytest** under `tests/`, mirroring the package structure; plain asserts,
  fixtures over setup methods.
- **Lock file:** `uv.lock` (committed); Renovate keeps the dependencies fresh.
<!-- /fragment:python -->
