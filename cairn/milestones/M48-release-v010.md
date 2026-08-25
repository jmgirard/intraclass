<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M48: v0.1.0 release consolidation — CRAN submission-ready

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M49, M50, M51, M53, M54, M55, M61, M68, M129, M130, M131, M132, M133, M134, M135, M136, M137   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2, GP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m048-release-v010`   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- AC1 → T1, T1b
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T5
- AC6 → T5
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Last-call API audit — one deliberate pass over the exported surface
      (`icc()`, `d_study()`, `choose_icc()`, S3 methods: names, argument
      order, defaults, return shapes) ending in a recorded disposition;
      expected outcome "no changes", anything substantive stops for a gate
      amendment. (RB tripwire: irreversible-api)
- [x] T1b: Apply the five accepted RR04 changes plus the two accepted extras —
      scalar `raters`/`posterior_summary` defaults and a loud abort on a
      multi-valued choice argument; always-present identifier columns in both
      tidiers; `var_subject_rater` + `n_o` in `glance.icc()`; the `icc`
      object's public/internal boundary stated in `@return`; classed
      validation of `d_study()`'s `conf_level`/`mc_samples`; `tidy()`'s
      `index` column renamed `term`; `rhat`/`ess_bulk` in `glance.icc()`.
      Each with a test and a NEWS line.
- [x] T2: Raise the R floor to `R (>= 4.0.0)` in `DESCRIPTION` (rlang binds
      the Imports chain; no 4.1+ syntax in package code).
- [x] T3: Stamp `Version: 0.1.0`; consolidate `NEWS.md` — fold the
      "(development version)" entries (M44–M47) into the pending 0.1.0
      changelog below them, one release heading (ADR-022 item d; ADR-055).
- [x] T4: Refresh `cran-comments.md` (current R versions/platforms checked,
      NOTE justifications) and re-verify `inst/WORDLIST` via the spelling
      check.
- [x] T5: Run the full local release gate and record outputs:
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

- 2026-07-12: created by /milestone-plan (promotes the release-consolidation candidate; plan gate: milestone-only vehicle, R ≥ 4.0.0, lightweight API audit, paper → candidate row).
- 2026-07-12: Depends-on amended to M49, M50, M51 by /milestone-plan ("address known issues" run; plan gate: the three hardening milestones land before the v0.1.0 release).
- 2026-07-16: Depends-on amended to add M53 by /milestone-plan (plan gate: maintainer sequenced the multilevel-SEM estimand/oracle pass ahead of the v0.1.0 release).
- 2026-07-16: Depends-on gains M54 (gated amendment at the M54 plan gate — maintainer chose to ship the lavaan multilevel engine before the release).
- 2026-07-17: Depends-on gains M55 by /milestone-plan (plan gate: the gtheory-reference docs audit lands before the v0.1.0 release — a capability table listing an archived package as an installable peer shouldn't ship in the first CRAN release).
- 2026-07-19: mirror catch-up by /milestone — Depends-on gained M61 (86d16e8, 2026-07-17 plan gate) and M68 (5a4a7af, 2026-07-18 plan gate: the references provenance backfill clears cairn_validate before M48's consistency gate); both were recorded in ROADMAP only, so this file's Depends-on and work log were behind.
- 2026-08-21: Depends-on gains M129, M130, M131, M132, M133 by /milestone-plan (plan gate: the maintainer asked for a pre-CRAN hardening slate — vignette transcripts backed, interval-methods claims backed, the Rd `\value`/shadowed-example nits, the two prose-only `icc()` argument values, and a per-`ci_method` trustworthiness table — to land before the first release; the v0.1.0 window was explicitly NOT declared at that gate and this milestone stays `blocked` on it, D-050).
- 2026-07-19: parked as `blocked` by /milestone — every dependency is satisfied so the mechanical next-action kept nominating this release, but the maintainer's v0.1.0 release window is not open; blocker is the unopened window (D-050), reversed only by the maintainer declaring it.
- 2026-08-24: mirror catch-up by /milestone — Depends-on gained M134, M135, M136 (recorded in ROADMAP at the 2026-08-23 M134-M136 plan gate; this file's Depends-on was behind). Bookkeeping only; all three are now `done`.

- 2026-08-24: Depends-on gains M137 by /milestone-plan (plan gate: the maintainer asked for one more pre-CRAN pass — a claim audit over the prose M134-M136 rewrote — before the release; the v0.1.0 window was again NOT declared and this milestone stays `blocked` on it, D-050).
- 2026-08-25: maintainer declared the v0.1.0 release window open (D-050's blocker reversed by the only party who can); status blocked -> in-progress by /milestone-implement, branch `m048-release-v010`.
- 2026-08-25: question gate — (1) T1's exported-API last call goes to a Fable review via /milestone-brief (the irreversible-api tripwire, maintainer's choice); (2) T3 consolidates NEWS by folding the development entries into the matching 0.1.0 sections and dropping entries that only describe changes to unreleased code.
- 2026-08-25: blocked on RB04 — the T1 exported-API last call is briefed at `cairn/reviews/RB04-exported-api-last-call.md` (11 questions over the three exported functions, the 13 S3 methods, the tidy/glance shapes, and whether anything should be withheld from the first release).
- 2026-08-25: RB04 spawned and RR04 returned in-session ([F] review of the exported surface); ingested here, RB/RR pair archived, status back to in-progress.
- 2026-08-25: gated amendment — Tasks gain T1b and Coverage's AC1 line gains it, executing the RR04 triage below; no acceptance criterion changed.
- 2026-08-25: T1 done — the last-call audit ran as RB04/RR04 and its disposition is recorded in the Decisions section below: the surface ships as audited but for seven accepted changes, two of them promoted to D-035.
- 2026-08-25: T1b done — the seven accepted changes applied across `R/icc.R`, `R/icc-methods.R`, `R/d-study.R`, `R/autoplot.R`, with `tests/testthat/test-exported-contract.R` (32 assertions) pinning both D-035 clauses, the `d_study()` validation, and the `glance()` replicate columns; the `index` -> `term` rename swept 20 test files (188 sites, [S] delegation, diff verified) and four vignettes. `devtools::test()` 0 failures, `air format --check` clean, `devtools::document()` rewrote `man/icc.Rd` and `man/d_study.Rd`.
- 2026-08-25: T2 done — `Depends: R (>= 4.0.0)` in DESCRIPTION; rlang is the binding Import (its own `Depends` is `R (>= 4.0.0)`, the highest in the chain: glmmTMB 3.6.0, lifecycle/generics 3.6, cli/tibble 3.4). No `|>` or `\(x)` syntax anywhere in `R/`, `tests/`, `vignettes/` or README. DESIGN.md's Platforms bullet corrected in place (it named the 3.5 floor as a leftover to fix here).
- 2026-08-25: T3 done — `Version: 0.1.0` stamped; NEWS.md consolidated under one `# intraclass 0.1.0` heading, 796 lines -> 407. The development entries fold into the release sections by topic; entries that only described changing unreleased code are dropped (the two `Correction.` bullets withdrawing wording no release ever carried, the Bug fixes section, and the Documentation section's rewrite notes), with each live fact they established kept as a plain statement. Two sections added to hold folded material: `Confidence intervals` (the six shipped `ci_method` values, the skew caveat, the abort-remedy naming, the Spearman-Brown pole) and `Reading a fit` (the tidy/glance contract from T1b). No `(development version)` heading remains.
- 2026-08-25: RR04's adjacent note settled — both `experimental` lifecycle badges (README package-level, `d_study()`'s roxygen) are kept deliberately for 0.1.0: experimental is the honest stage for a first release, and RR04 declined to withhold `d_study()` precisely because its badge already carries that signal.
- 2026-08-25: T3 follow-up — the release-gate run caught two guards the consolidation had broken, both restored rather than relaxed: `test-doc-skew-caveat.R` requires NEWS to carry one width-margin and one residual statement in the canonical verbatim clauses (the material the dropped `Correction.` bullets carried), now re-stated as first-release facts; and `data-raw/check-mpl-doc-claims.py` anchors its NEWS sweep on the `* The \`ci_method = "mpl"\` documentation` bullet, restored verbatim so every ledger key stays valid. Both green.
- 2026-08-25: `inst/WORDLIST` grew 66 -> 94 words; `spelling::spell_check_package()` clean. The 28 additions were already unlisted before this milestone (last touched M123). Five are British forms in an `en-US` package (`colourblind`, `favouring`, `labelling`, `relabelled`, `relabellings`, plus `trialled`); wordlisted rather than respelled, since respelling means rewriting prose the M134-M136 passes own during release week.
- 2026-08-25: T5 partial — `devtools::document()` no delta, `air format --check` clean, `lintr::lint_package()` 0 lints, `urlchecker::url_check()` all correct, `pkgdown::check_pkgdown()` no problems, `pkgdown::build_site()` clean (every vignette knits), spelling clean, and the six `data-raw/` CI checkers plus their self-tests all exit 0. Installed-package suite with `NOT_CRAN=true CI=true`: FAIL 0 | WARN 2 | SKIP 26 | PASS 8574 (AC5). `devtools::check(--as-cran)` not yet run.
- 2026-08-25: T5 done — `devtools::check(args = "--as-cran", env_vars = c(NOT_CRAN = "false"), manual = TRUE)` on R 4.6.1 / aarch64-apple-darwin23: **Status: OK, 0 errors | 0 warnings | 0 notes**, duration 2m 2s, PDF and HTML manuals both built (AC4).
- 2026-08-25: T4 done — `cran-comments.md` refreshed against that run: the check date, environment and 0/0/0 result are the ones just observed, the R-floor rationale is stated, and the Suggests-gating note is unchanged. Nothing left to justify, there being no NOTE.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-08-25 (RR04 ingest, T1 disposition): the exported surface ships as
  audited except for seven accepted changes. **Applied** (RR04 recommendations
  1-5, accepted at the 2026-08-25 gate): scalar `raters`/`posterior_summary`
  defaults with a loud abort on a multi-valued choice argument; identifier
  columns always present in `tidy.icc()`/`tidy.icc_dstudy()`, NA where
  inapplicable; `var_subject_rater` and `n_o` added to `glance.icc()` so
  `var_residual` never silently changes meaning on a replicate fit; the `icc`
  object's public/internal boundary stated in `@return`; classed validation of
  `d_study()`'s `conf_level` and `mc_samples`. **Also applied** (RR04 6 and 7):
  `tidy()`'s `index` column renamed `term` for broom-ecosystem interop;
  `rhat`/`ess_bulk` surfaced in `glance.icc()`. Clauses 1 and 4 are promoted to
  D-035. Task T1b carries the work.
- 2026-08-25 (RR04 ingest, deferred): RR04 recommendation 8 — `choose_icc()`
  accepting `type = "both"` — is additive after release and goes to a ROADMAP
  candidate row rather than into this milestone.
- 2026-08-25 (RR04 ingest, reviewer rejections logged, no action): reverting
  the vectorized `type`/`unit`/`level` defaults (9); renaming
  `rater`/`raters`, `model`/`design`, or `level` (10) — every traced confusion
  already aborts classed; dropping `lifecycle` from Imports (11) — it backs the
  `d_study()` experimental badge and the check-note scaffolding, and the brief's
  premise that it was unused was wrong; withholding any current export (12);
  per-method `.Rd` pages (13) — all thirteen methods are aliased onto their
  objects' pages, which R CMD check accepts. RR04's adjacent note that the
  release should decide deliberately what the README and `d_study()` lifecycle
  badges say for a 0.1.0 is carried into T3.

## Review
<!-- owner: review · exclusive -->
