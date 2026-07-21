# M77: Speed up CI with three low-risk workflow-config changes

**Status:** done (2026-07-21, PR #83 https://github.com/jmgirard/intraclass/pull/83)

**Goal:** Cut CI wall-clock and wasted runs by adding run-cancellation, path filtering, and an event-conditional check matrix to the GitHub Actions workflows — no change to package behavior.

**Outcome:** Three edits under `.github/workflows/`. (1) A `concurrency` block (`group: ${{ github.workflow }}-${{ github.ref }}`) on check-standard, test-coverage, lint, format with `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}` — PR/branch runs auto-cancel, `main` is exempt so double-merges never lose a full-matrix run. (2) `paths-ignore: ['cairn/**','man/**','README.md','**/*.Rmd']` on both `push` and `pull_request` of check-standard + test-coverage, so tracking/docs-only pushes to `main` skip the heavy dependency matrix. (3) check-standard's matrix made event-conditional via a `fromJSON` ternary: full 5 configs on push to `main`, `ubuntu-latest + windows-latest release` on PRs (Windows kept for the M56 flake). Not addressed: per-run dependency-install time (the dominant CI cost — see the new CI-dep-caching candidate).

**Decisions:** none cross-cutting. AC1 amended at the merge gate (literal `true` → `main`-exempt expression) per maintainer choice.

**Review:** 3-lens fan-out ([O] diff-bug, [S] blame-history, [S] prior-PR-comments) — zero findings; scorer no-op. Diff-bug reviewer's `main`-cancellation caveat was resolved by the AC1 amendment. All 8 PR checks green (ubuntu+windows R-CMD-check confirmed the 2-config PR matrix). Nothing graduated or retired.
