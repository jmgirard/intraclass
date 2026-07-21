# M77: Speed up CI with three low-risk workflow-config changes

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** m77-ci-speed-config · https://github.com/jmgirard/intraclass/pull/83

## Goal

Cut CI wall-clock and wasted runs by adding run-cancellation, path filtering, and an event-conditional check matrix to the GitHub Actions workflows — no change to package behavior.

## Scope

**In:** three config edits under `.github/workflows/`. (1) A `concurrency` block with `cancel-in-progress: true` on `check-standard.yaml`, `test-coverage.yaml`, `lint.yaml`, `format.yaml`, so a new push to a ref cancels that ref's in-flight run. (2) `paths-ignore: ['cairn/**','man/**','README.md','**/*.Rmd']` on **both** the `push` and `pull_request` triggers of `check-standard.yaml` + `test-coverage.yaml`, so tracking/docs-only commits (frequent, and landed directly on `main` here) skip the heavy dependency-install matrix. (3) `check-standard.yaml`'s job matrix made event-conditional via a `fromJSON` ternary: the full 5-config matrix on `push` to `main`, a slim `ubuntu-latest release + windows-latest release` matrix on `pull_request`.

**Out:** measuring/asserting the actual wall-clock saving beyond observing the runs (CI timing is noisy — no numeric pin). `concurrency`/`paths-ignore` on `pkgdown.yaml` + `reference-values.yaml` (not in the ask → left untouched; a later candidate if wanted). `paths-ignore` on `lint.yaml`/`format.yaml` (declined at the plan gate 2026-07-21 — cheaper jobs, smaller gain). No R package code changes, so the R test suite is not this milestone's gate.

## Acceptance criteria

- [x] AC1: `check-standard.yaml`, `test-coverage.yaml`, `lint.yaml`, `format.yaml` each carry a top-level `concurrency` block keyed on workflow+ref with `cancel-in-progress: true` (grep/actionlint evidence).
- [x] AC2: `check-standard.yaml` and `test-coverage.yaml` carry `paths-ignore: ['cairn/**','man/**','README.md','**/*.Rmd']` on both the `push` and `pull_request` triggers (grep/actionlint evidence).
- [x] AC3: `check-standard.yaml`'s matrix resolves to the full 5 configs (macos, windows, ubuntu devel/release/oldrel-1) on `push` and to exactly `ubuntu-latest release` + `windows-latest release` on `pull_request` — evidenced by the milestone PR's own check run showing 2 configs, and by the post-merge push-to-`main` run showing 5.
- [x] AC4: all four edited workflow files are valid (`actionlint` clean; YAML parses) — no syntax/expression errors introduced.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Add the `concurrency` block (`group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: true`) to all four workflows.
- [x] T2: Add `paths-ignore` to the `push` and `pull_request` triggers of `check-standard.yaml` + `test-coverage.yaml` (expand each bare trigger to carry the filter; keep `push` branch filter).
- [x] T3: Replace `check-standard.yaml`'s static `matrix.config` list with a `${{ github.event_name == 'push' && fromJSON('[...5...]') || fromJSON('[...ubuntu+windows release...]') }}` expression.
- [x] T4: Run `actionlint` on the four files; confirm clean. At review, read the PR's own check run to confirm 2 configs fired.

## Work log

- 2026-07-21: created by /milestone-plan. Gate decisions: PR matrix = ubuntu+windows release (preserves the M56 Windows-only-flake gate before merge); paths-ignore on both push+pull_request of check+coverage (tracking commits land on main directly here); lint/format paths-ignore declined. Branch protection on main is absent → no required-check-vs-paths-ignore hang risk.
- 2026-07-21: T1–T4 done. Concurrency block on all four workflows; paths-ignore on push+pull_request of check-standard+test-coverage; check-standard matrix now event-conditional via fromJSON ternary (push→5 configs, PR→ubuntu+windows release). `actionlint` clean (1.7.12, exit 0) on all four; matrix JSON verified to parse to 5/2 configs. No R code touched, so devtools verify slot N/A. Status → review.

## Decisions

## Review

**Acceptance criteria — fresh evidence (2026-07-21):**
- AC1: `grep -l "cancel-in-progress: true"` returns all four workflows. ✓
- AC2: `grep -c paths-ignore` = 2 in both check-standard and test-coverage (push + pull_request); absent from lint/format as planned. ✓
- AC3: PR #83's own run spawned R-CMD-check jobs `ubuntu-latest (release)` + `windows-latest (release)` and no others — the 2-config PR matrix live-verified. The 5-config push branch is verified structurally (matrix JSON parses to the original 5 configs) and runs post-merge on `main`. ✓
- AC4: `actionlint` 1.7.12 clean (exit 0) on all four files. ✓

**Consistency gate:** `cairn_validate` exit 0, all checks PASS (incl. `coverage complete`); 296 dangling-id warnings are pre-existing archived-ID advisories. No `.R`/roxygen changed → `devtools::document()` trivially no-diff, `man/` untouched; no NEWS entry (not user-facing package behavior). No principle changed → `cairn_impact` skipped.

**Independent review (3 lenses + scorer):** [O] diff-bug, [S] blame-history, [S] prior-PR-comments — all reported **zero surviving findings**. Scorer no-op (no findings to score). The blame/prior-review lenses confirmed the PR-matrix slim is a documented, deliberate accommodation of the M56 Windows-only-flake lesson (Windows kept on PRs; full matrix post-merge), not a silent regression; probe found no real GitHub review threads (`[]`).
- Informational caveat (logged, not a defect, scored N/A): `cancel-in-progress: true` also applies on `main`, so two merges in quick succession would cancel the first's full 5-config run and lose that commit's default-branch CI signal. Intentional consequence of the requested unconditional `cancel-in-progress`; surfaced to the maintainer at the approval gate.
