---
name: finish-task
description: Close out the current task. Use when the maintainer says "finish the task", "wrap up", or "close this out". Runs checks and only marks done on green.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

## Where changes go (branch vs. direct-to-`main`)
Pragmatic policy (maintainer preference; `main` is not currently branch-protected):

- **PR required** — anything the CI matrix builds or inspects, because it can turn
  `main` red: `R/`, `tests/`, `vignettes/`, `DESCRIPTION`, `NAMESPACE`, `man/`, and
  CI/tooling config (`.github/workflows/`, `air.toml`, `.lintr`, `_pkgdown.yml`).
  Ship on a `m<N>-<slug>` (milestone) or short `chore-*`/`fix-*` branch → PR → merge.
- **Direct commit to `main` is fine** — changes no CI job looks at: `project/`
  tracking docs, `.claude/` skills/agents, memory files, `ROADMAP.md`. A PR for these
  only burns CI minutes with no gate value.

If a commit mixes both (e.g. code + its `project/` tracking updates in one commit,
PRINCIPLES.md #16), the code makes the whole commit PR-bound.

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
- Commit the work on the milestone branch `m<N>-<slug>` (create it at the
  milestone's first commit); package/CI-config work merges via a **PR**, never
  direct to `main` (see "Where changes go" above and the
  `milestone-branches-and-prs` memory).
**Single-source each fact (ADR-015 — the primary anti-lapse rule).** Each fact has
one home; every other file *links*, never restates. Update the fact where it lives,
not in several places: milestone plan + status → `MILESTONES.md`; active task / next
action / last-green-CI / blockers → `STATUS.md` (a pointer, not a history); an
oracle's asserted-state → its **test file**, named by `REFERENCES.md`; future ideas →
`ROADMAP.md`. If you catch yourself restating the same status in a second file, that
second copy is a future lapse — link instead.

- Check off the task in the **active milestone's DoD checklist in
  `project/MILESTONES.md`** (that checklist is the board — there is no `TASKS.md`).
- Update `project/STATUS.md` (active task, next action, updated date; set "Last green
  CI" only after the PR's CI is green and the branch is merged). Keep it a *pointer* —
  do not re-enumerate shipped milestones (that record is `MILESTONES.md`).
- **If this task completes a milestone:** update that milestone's **Status line** in
  `project/MILESTONES.md` — do not leave it marked in-progress once its checklist is
  fully checked. (The board is the checklist itself; nothing to condense elsewhere.)
  Then, once it is **merged** (post-PR, in the reconcile pass below), **compress the
  shipped milestone's entry** to the summary form the file uses for shipped work —
  Goal (1–2 lines) / references (ADR + estimand-spec) / **Deferred** / Status — and
  drop the full `[x]` DoD checklist (recoverable from the ADR, the estimand-spec, and
  git). **Preserve the "Deferred out of M<n>" list verbatim** — it is load-bearing.
  Keep only the *active* and *next* milestones fully detailed (ADR-015).
- If a statistical or architectural decision was made, add an ADR via `add-decision`.
- **Reconcile `project/REFERENCES.md`** (part of the same-commit tracking set, #16 —
  not an afterthought). Two moves, not just one:
  1. Add rows for any genuinely **new** oracle value, with provenance (#4).
  2. **Transition every oracle this task just proved** from `planned` /
     `not yet asserted` to **`asserted (M<n>)`** naming its test file, and its
     provenance from `to be committed` to **committed**. (An oracle scaffolded as
     `planned` by `new-estimator` stays `planned` until *this* step flips it — the
     M5 close-out skipped it and left O-ML stuck on "planned" for two milestones.)
- **Sweep `project/` for now-resolved forward-references.** A shipped milestone
  turns *forward-looking* language about it — everywhere, not just its own entry —
  stale. Before proposing the commit, run
  `grep -rniE 'planned|not yet|to be (committed|written|asserted)|to fix|forthcoming|provisional|next milestone|detail (it|its|at)|deferred to M[0-9]|Slice [0-9]' project/`
  and reconcile every hit the just-shipped work (or a renumber) resolved.
  Genuinely-still-future items (a later milestone, a ROADMAP deferral) stay; a
  forward-reference whose target has shipped is stale. **Two spots lapse the most and
  live *outside* the milestone's own entry — check them by name every ship:**
  1. **`MILESTONES.md` preamble** — the "Shipped milestones (M0–M<x>) are fully
     specified; the remaining ones (M<x+1>–M9) are provisional" line must advance so
     the just-shipped milestone is no longer called provisional.
  2. **`ROADMAP.md` "Resolved" entries** — a promoted item reads "promoted to M<n>
     (the next milestone) … detail its DoD at milestone start"; once it ships, flip it
     to "shipped as M<n>" and drop the detail-at-start language.
  Also reconcile any **cross-milestone deferral** whose target moved in a renumber
  (e.g. "deferred to M6" written before ADR-013 shifted optional engines to M7).
  Dated ADRs in `DECISIONS.md` are the exception — they are append-only history and
  are *not* rewritten to match a later renumber.
- Propose a Conventional Commit message; remind that tracking-file updates ship in
  the **same commit** as the work (PRINCIPLES.md #16).

**Leave no transient status marker dangling.** Phrases like `pending PR CI + merge`,
`done (local)`, or `in progress` (and, in `REFERENCES.md`, `planned` /
`not yet asserted` / `to be committed`) describe a *transition that has not finished
yet*. The moment the transition completes, the marker is stale and must be reconciled
to reality across `STATUS.md`, `MILESTONES.md`, **and `REFERENCES.md`** in the same
pass — REFERENCES lapses the most quietly because no CI job reads it.

## After PR CI green + merge
`finish-task` runs before the PR is opened, so it cannot confirm CI. Open a PR from
the milestone branch (`gh pr create`); once its full CI matrix is green and the
branch is **merged** to `main`, reconcile the deferred markers. This touches only
`project/` docs, so per "Where changes go" it is a **direct commit to `main`** (no
PR needed), on an up-to-date `main` (PRINCIPLES.md #16):
- Set `STATUS.md` "Last green CI" to the merge commit.
- Flip every `pending PR CI + merge` / `done (local)` marker for the shipped work to
  **merged, CI green** in `MILESTONES.md` (its Status line).
- Sanity check: `git rev-list --count origin/main...main` is `0`, nothing labeled
  `pending PR CI + merge` remains in `project/`, and the forward-reference sweep
  (above) is clean — every `planned` / `not yet asserted` / `to be committed` /
  `to fix in Slice N` left in `project/` genuinely still points at unshipped work.
