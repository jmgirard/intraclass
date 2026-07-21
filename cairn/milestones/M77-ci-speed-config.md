# M77: Speed up CI with three low-risk workflow-config changes

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** m77-ci-speed-config

## Goal

Cut CI wall-clock and wasted runs by adding run-cancellation, path filtering, and an event-conditional check matrix to the GitHub Actions workflows — no change to package behavior.

## Scope

**In:** three config edits under `.github/workflows/`. (1) A `concurrency` block with `cancel-in-progress: true` on `check-standard.yaml`, `test-coverage.yaml`, `lint.yaml`, `format.yaml`, so a new push to a ref cancels that ref's in-flight run. (2) `paths-ignore: ['cairn/**','man/**','README.md','**/*.Rmd']` on **both** the `push` and `pull_request` triggers of `check-standard.yaml` + `test-coverage.yaml`, so tracking/docs-only commits (frequent, and landed directly on `main` here) skip the heavy dependency-install matrix. (3) `check-standard.yaml`'s job matrix made event-conditional via a `fromJSON` ternary: the full 5-config matrix on `push` to `main`, a slim `ubuntu-latest release + windows-latest release` matrix on `pull_request`.

**Out:** measuring/asserting the actual wall-clock saving beyond observing the runs (CI timing is noisy — no numeric pin). `concurrency`/`paths-ignore` on `pkgdown.yaml` + `reference-values.yaml` (not in the ask → left untouched; a later candidate if wanted). `paths-ignore` on `lint.yaml`/`format.yaml` (declined at the plan gate 2026-07-21 — cheaper jobs, smaller gain). No R package code changes, so the R test suite is not this milestone's gate.

## Acceptance criteria

- [ ] AC1: `check-standard.yaml`, `test-coverage.yaml`, `lint.yaml`, `format.yaml` each carry a top-level `concurrency` block keyed on workflow+ref with `cancel-in-progress: true` (grep/actionlint evidence).
- [ ] AC2: `check-standard.yaml` and `test-coverage.yaml` carry `paths-ignore: ['cairn/**','man/**','README.md','**/*.Rmd']` on both the `push` and `pull_request` triggers (grep/actionlint evidence).
- [ ] AC3: `check-standard.yaml`'s matrix resolves to the full 5 configs (macos, windows, ubuntu devel/release/oldrel-1) on `push` and to exactly `ubuntu-latest release` + `windows-latest release` on `pull_request` — evidenced by the milestone PR's own check run showing 2 configs, and by the post-merge push-to-`main` run showing 5.
- [ ] AC4: all four edited workflow files are valid (`actionlint` clean; YAML parses) — no syntax/expression errors introduced.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [ ] T1: Add the `concurrency` block (`group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: true`) to all four workflows.
- [ ] T2: Add `paths-ignore` to the `push` and `pull_request` triggers of `check-standard.yaml` + `test-coverage.yaml` (expand each bare trigger to carry the filter; keep `push` branch filter).
- [ ] T3: Replace `check-standard.yaml`'s static `matrix.config` list with a `${{ github.event_name == 'push' && fromJSON('[...5...]') || fromJSON('[...ubuntu+windows release...]') }}` expression.
- [ ] T4: Run `actionlint` on the four files; confirm clean. At review, read the PR's own check run to confirm 2 configs fired.

## Work log

- 2026-07-21: created by /milestone-plan. Gate decisions: PR matrix = ubuntu+windows release (preserves the M56 Windows-only-flake gate before merge); paths-ignore on both push+pull_request of check+coverage (tracking commits land on main directly here); lint/format paths-ignore declined. Branch protection on main is absent → no required-check-vs-paths-ignore hang risk.

## Decisions

## Review
