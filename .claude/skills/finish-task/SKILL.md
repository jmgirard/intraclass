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
- **If this task completes a milestone:** update that milestone's **Status line** in
  `project/MILESTONES.md` and condense its `project/TASKS.md` board to one line — do
  not leave the milestone marked in-progress once its board is fully checked.
- If a statistical or architectural decision was made, add an ADR via `add-decision`.
- Update `project/REFERENCES.md` if any new oracle value was introduced.
- Propose a Conventional Commit message; remind that tracking-file updates ship in
  the **same commit** as the work (PRINCIPLES.md #16).

**Leave no transient status marker dangling.** Phrases like `pending push`,
`done (local)`, or `in progress` describe a *transition that has not finished yet*.
The moment the transition completes, the marker is stale and must be reconciled to
reality across `STATUS.md`, `MILESTONES.md`, and `TASKS.md` in the same pass.

## After push + CI green
`finish-task` runs before the push, so it cannot confirm CI. Once you have pushed
and the full CI matrix is confirmed green on `origin`, reconcile the deferred
markers in one commit (PRINCIPLES.md #16):
- Set `STATUS.md` "Last green CI" to the pushed commit.
- Flip every `pending push` / `done (local)` marker for the shipped work to
  **pushed, CI green** in `MILESTONES.md` and `TASKS.md`.
- Sanity check: `git rev-list --left-right --count origin/main...HEAD` — if it is
  `0  0`, nothing labeled "pending push" may remain in `project/`.
