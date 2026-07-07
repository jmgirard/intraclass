---
name: finish-task
description: Close out the current task. Use when the maintainer says "finish the task", "wrap up", or "close this out". Runs checks and only marks done on green.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

## Instructions
Run the full local gate and **only mark done on green** (PRINCIPLES.md #10, #11, #16):

1. `R -q -e 'devtools::document()'` — regenerate docs/NAMESPACE if roxygen changed.
2. `air format .` — auto-format code (air.toml); the CI `format.yaml` job enforces
   `air format --check .`, so format locally before committing.
3. `R -q -e 'devtools::test()'` — all tests pass; no unexpected skips.
4. `R -q -e 'devtools::check()'` — 0 errors, 0 warnings; every note justified.
5. `R -q -e 'lintr::lint_package()'` — no new lints (air owns layout; lintr the rest).
6. `R -q -e 'covr::package_coverage()'` — ≥90%, statistical paths oracle-covered.

If anything is red: report exactly what failed with output, **do not** mark the
task done, and stop. Never loosen an oracle tolerance to pass (PRINCIPLES.md #1).

On green:
- Check off the task in `project/TASKS.md`.
- Update `project/STATUS.md` (active task, last green CI once pushed, updated date).
- If a statistical or architectural decision was made, add an ADR via `add-decision`.
- Update `project/REFERENCES.md` if any new oracle value was introduced.
- Propose a Conventional Commit message; remind that tracking-file updates ship in
  the **same commit** as the work (PRINCIPLES.md #16).
