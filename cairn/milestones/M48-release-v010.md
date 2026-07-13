<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M48: v0.1.0 release consolidation — CRAN submission-ready

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2, GP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Consolidate the post-M44–M47 package state into a CRAN-submission-ready v0.1.0
(the upload itself stays the maintainer's out-of-band act, per ADR-022).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** last-call exported-API audit (GP2's one-way door closes at submission);
honest R floor (`R (>= 4.0.0)`, rlang-bound — GP3, plan gate 2026-07-12);
version stamp `0.1.0` + NEWS consolidated under one `# intraclass 0.1.0`
heading (ADR-022 item d, ADR-055 mechanics); refreshed `cran-comments.md`;
the full release gate re-run fresh (the 81a53ae green state is stale by
M44–M47 + the cairn migration). All mechanics as milestone tasks — the
`/cairn-release` skill is deliberately not used (plan gate 2026-07-12).

**Out:** the CRAN upload + win-builder/R-hub round-trips → maintainer,
out of band (ADR-022, standing); the companion paper → ROADMAP candidate
row (added by this plan); post-release semver flow → after first release
(ADR-055); any substantive API change the audit surfaces → escalated at the
gate before stamping, never folded in silently.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: API last-call disposition is recorded in the work log (audit of
      exports, argument names/order, defaults, return shapes); no exported-
      surface change ships after it without a gate amendment. (RB tripwire:
      irreversible-api)
- [ ] AC2: `DESCRIPTION` has `Version: 0.1.0` and `R (>= 4.0.0)`; `NEWS.md`
      opens with a single consolidated `# intraclass 0.1.0` changelog (no
      "(development version)" heading; M44's default-shape change framed as
      part of the initial release per ADR-055).
- [ ] AC3: `cran-comments.md` names the actual check environments used and
      justifies every remaining NOTE; `inst/WORDLIST`/spelling clean.
- [ ] AC4: fresh `devtools::check(args = "--as-cran", env_vars =
      c(NOT_CRAN = "false"), manual = TRUE)` → 0 errors / 0 warnings / only
      NOTEs justified in AC3 (TinyTeX courier installed for the PDF manual).
- [ ] AC5: full test suite green against the **installed** package with
      `NOT_CRAN=true CI=true` (failed + error sum = 0 — the local-gate
      blind spot).
- [ ] AC6: `pkgdown::check_pkgdown()` + `pkgdown::build_site()` clean;
      `air format --check` clean; `lintr::lint_package()` clean;
      `urlchecker::url_check()` all-correct.
- [ ] AC7: full CI matrix green on the PR head (R-devel setup flake → re-run
      the job, don't debug the diff).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T5
- AC6 → T5
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Last-call API audit — one deliberate pass over the exported surface
      (`icc()`, `d_study()`, `choose_icc()`, S3 methods: names, argument
      order, defaults, return shapes) ending in a recorded disposition;
      expected outcome "no changes", anything substantive stops for a gate
      amendment. (RB tripwire: irreversible-api)
- [ ] T2: Raise the R floor to `R (>= 4.0.0)` in `DESCRIPTION` (rlang binds
      the Imports chain; no 4.1+ syntax in package code).
- [ ] T3: Stamp `Version: 0.1.0`; consolidate `NEWS.md` — fold the
      "(development version)" entries (M44–M47) into the pending 0.1.0
      changelog below them, one release heading (ADR-022 item d; ADR-055).
- [ ] T4: Refresh `cran-comments.md` (current R versions/platforms checked,
      NOTE justifications) and re-verify `inst/WORDLIST` via the spelling
      check.
- [ ] T5: Run the full local release gate and record outputs:
      `devtools::document()` (no delta), `air format --check`,
      `lintr::lint_package()`, `urlchecker::url_check()`,
      `pkgdown::check_pkgdown()` + `build_site()`, installed-package test
      pass with `NOT_CRAN=true CI=true`, then
      `devtools::check(args = "--as-cran", env_vars = c(NOT_CRAN = "false"),
      manual = TRUE)`.
- [ ] T6: Open the PR and drive the CI matrix green (one blocking
      `gh pr checks --watch`; re-run infra flakes).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan (promotes the release-consolidation
  candidate; plan gate: milestone-only vehicle, R ≥ 4.0.0, lightweight API
  audit, paper → candidate row).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
