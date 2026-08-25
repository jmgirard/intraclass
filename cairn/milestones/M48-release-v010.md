<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M48: v0.1.0 release consolidation — CRAN submission-ready

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M49, M50, M51, M53, M54, M55, M61, M68, M129, M130, M131, M132, M133, M134, M135, M136, M137   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2, GP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m048-release-v010` · https://github.com/jmgirard/intraclass/pull/147   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: API last-call disposition is recorded in the work log (audit of
      exports, argument names/order, defaults, return shapes); no exported-
      surface change ships after it without a gate amendment. (RB tripwire:
      irreversible-api)
- [x] AC2: `DESCRIPTION` has `Version: 0.1.0` and `R (>= 4.0.0)`; `NEWS.md`
      opens with a single consolidated `# intraclass 0.1.0` changelog (no
      "(development version)" heading; M44's default-shape change framed as
      part of the initial release per ADR-055).
- [x] AC3: `cran-comments.md` names the actual check environments used and
      justifies every remaining NOTE; `inst/WORDLIST`/spelling clean.
- [x] AC4: fresh `devtools::check(args = "--as-cran", env_vars =
      c(NOT_CRAN = "false"), manual = TRUE)` → 0 errors / 0 warnings / only
      NOTEs justified in AC3 (TinyTeX courier installed for the PDF manual).
- [x] AC5: full test suite green against the **installed** package with
      `NOT_CRAN=true CI=true` (failed + error sum = 0 — the local-gate
      blind spot).
- [x] AC6: `pkgdown::check_pkgdown()` + `pkgdown::build_site()` clean;
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
- [x] T6: Open the PR and drive the CI matrix green (one blocking
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
- 2026-08-25: T1b follow-up — the `index` -> `term` rename also reached `data-raw/`: the `checkpoint-guard` CI job runs `m120-checkpoint-guard-demo.R`, whose sweep harness read `tidy()$index`, and it reddened on the first PR head. 12 sites across 10 scripts ([S] delegation, diff verified; `$estimates$index` reaches left alone); the demo passes locally and the job is green on the second head.
- 2026-08-25: T6 done — PR #147 opened; every check on the head is green: `ubuntu-latest (release)` 22m17s, `windows-latest (release)` 25m35s, `test-coverage` 37m34s, `codecov/patch`, `codecov/project`, `checkpoint-guard`, `lint`, `format-check`, `check-references`, `pkgdown`. **Note for the review gate on AC7:** `check-standard.yaml`'s matrix is conditional — the five-cell set (macOS release, Windows release, ubuntu devel/release/oldrel-1) runs on `push` to the default branch only, and a `pull_request` event gets the two-cell set that ran here. The full matrix therefore runs on the merge commit, before any submission, and cannot be run on a PR head as the workflow now stands.
- 2026-08-25: all tasks checked; status in-progress -> review by /milestone-implement.
- 2026-08-25: review checkpoint (mid-phase) by /milestone-review — AC1-AC4 and AC6 verified with fresh evidence and ticked; AC5 (installed-package suite) still running; AC7's disposition open, the criterion asking for a matrix the workflow cannot run on a PR head since M77. Consistency gate green. Two of three review lenses returned, no actionable findings.
- 2026-08-25: review returns M48 to in-progress by /milestone-review — AC7 fails as written (the five-config CI matrix is gated on a push event to the default branch since M77, so it cannot run on a PR head; routed as an amendment return, no criterion text changed here), and the [O] diff-bug lens found two reproduced defects: `glance()$n_o` is NA on nested Design 2 replicate fits while `var_subject_rater` is populated, contradicting `?icc` and NEWS; and NEWS promises classed `boot_samples`/`seed` validation in `d_study()` that does not exist, `d_study(seed = c(1, 2))` silently taking the first element and `seed = "abc"` raising an unclassed error. AC1-AC6 verified with fresh evidence; consistency gate green. Findings and dispositions in the Review section.

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

### Acceptance-criterion evidence (fresh, 2026-08-25)

- **AC1 — verified.** The last-call disposition is recorded in the work log
  (2026-08-25, T1) and carried in full by the Decisions section above: the
  surface ships as audited but for seven accepted RR04 changes, one deferral to
  a ROADMAP candidate row, and five logged rejections. No exported-surface
  change shipped after the audit outside a gate: `git log --stat
  origin/main..HEAD` shows `R/` touched by exactly one commit, `4ba59ad`
  (T1b), which the 2026-08-25 gated-amendment work-log line authorises;
  `NAMESPACE` is byte-identical to `origin/main`.
- **AC2 — verified.** `DESCRIPTION` line 3 `Version: 0.1.0`, lines 53-54
  `Depends: R (>= 4.0.0)`. `grep '^# ' NEWS.md` returns exactly one heading,
  `# intraclass 0.1.0`; a case-insensitive sweep for "development version"
  returns 0 hits.
- **AC3 — verified.** `cran-comments.md` names the environment the fresh AC4
  run actually used (R 4.6.1, aarch64-apple-darwin23, `NOT_CRAN=false`,
  `manual = TRUE`, 2026-08-25) and the 0/0/0 result; with no NOTE there is
  nothing left to justify, and the file says so. `spelling::spell_check_package()`
  re-run fresh: no spelling errors found. One qualification, raised as finding
  R1 below rather than held against the tick: the file's "Test environments"
  block also lists the GitHub Actions five-config matrix, which the workflow
  runs only on push to the default branch and which has therefore not yet run
  against this code.
- **AC4 — verified.** `devtools::check(args = "--as-cran", env_vars =
  c(NOT_CRAN = "false"), manual = TRUE)` re-run fresh on this head: R 4.6.1,
  platform aarch64-apple-darwin23, `--as-cran` confirmed in the check banner.
  **Status: OK — 0 errors | 0 warnings | 0 notes**, duration 2m 9.7s; PDF and
  HTML manuals both built OK.
- **AC5 — verified.** `R CMD INSTALL` of this head, then
  `NOT_CRAN=true CI=true Rscript -e 'library(testthat); library(intraclass);
  test_check("intraclass")'` from `tests/` against the **installed** package
  (R 4.6.1, aarch64-apple-darwin23): **`[ FAIL 0 | WARN 2 | SKIP 26 |
  PASS 8574 ]`** — failed + error sum = 0, the criterion's bar. The two
  warnings are the expected boundary/connectedness signals from
  `test-icc-lavaan-multilevel.R:402` and `test-icc-type-vector.R:286`, which
  the criterion does not bar.
- **AC6 — verified**, all five checks re-run fresh on this head:
  `pkgdown::check_pkgdown()` "No problems found"; `pkgdown::build_site()`
  exit 0, all eight vignettes read and rendered, no error or warning in the
  log; `air format --check .` exit 0; `lintr::lint_package()` 0 lints;
  `urlchecker::url_check()` "All URLs are correct!" over 15 URLs.
- **AC7 — NOT verified; the criterion cannot hold as written.** AC7 asks for
  the "full CI matrix green on the PR head" and names R-devel in its
  parenthetical. `.github/workflows/check-standard.yaml:37` makes the matrix
  conditional on `github.event_name == 'push'`, and `on.push.branches` is
  `[main, master]`: a `pull_request` event gets a two-cell set
  (`ubuntu-latest release`, `windows-latest release`), and a push to a
  milestone branch does not trigger the workflow at all. The five-cell set
  (macOS release, Windows release, ubuntu devel/release/oldrel-1) can
  therefore never run on a PR head. That conditional landed in **M77**
  (`28923266`, 2026-07-21), nine days after AC7 was written (2026-07-12),
  when the full matrix *did* run on PR heads — so the criterion was falsified
  by a later milestone, not by this work, and no work inside M48's Scope can
  satisfy it. What is measured on the head: eight checks, of which
  nine are green (`format-check`, `lint`, `pkgdown`, `check-references`,
  `checkpoint-guard`, `test-coverage`, `codecov/patch`, `codecov/project`,
  `ubuntu-latest (release)`) and `windows-latest (release)` was still running
  at this writing. Routed as an amendment return, below.

### Consistency gate

- `cairn_validate.py` exit 0 — every check PASS, every advisory OK; the
  `release window` advisory did not fire.
- `cairn_impact.py` not run: no `DESIGN.md` IP/GP principle changed (the
  file's only diff is the Platforms commitment bullet).
- Toolchain checks, from the `r-package` profile's `consistency-gate` slot:
  `devtools::document()` leaves a clean tree; `NAMESPACE`, `_pkgdown.yml` and
  `data/` are byte-identical to `origin/main`, so no generated file was
  hand-edited and no new export is missing a reference-index row; `README.Rmd`
  and `README.md` were last written by the same commit (`5c274fc`) and neither
  is touched here; `pkgdown::check_pkgdown()` clean; `NEWS.md` carries the
  user-visible changes of this milestone and a sweep for milestone / ADR / D /
  RR ids across `NEWS.md`, `README.md`, `man/` and `vignettes/` returns
  nothing; no new top-level file, so no `.Rbuildignore` entry is owed; the
  full `--as-cran` check is the AC4 run above.

### Review fan-out

Three fresh-context lenses, each on a distinct evidence base, none having
authored the implementation. Every reported finding is logged below with its
disposition.

- **[S] prior-review lens — no findings.** The probe
  `gh api repos/jmgirard/intraclass/pulls/comments?per_page=1` returned `[]`
  (no inline review comment exists anywhere in the repo's PR history), so the
  per-PR walk was skipped. Across the archived `## Review` sections touching
  these files it found no point this diff reintroduces or contradicts, and
  verified RR04 recommendations 1-7 applied faithfully, including the
  deliberate carve-out that the *printed* table header still reads `index`.
- **[S] blame-history lens — no actionable findings.** Seven items, all
  confirmatory: the NEWS fold of the withdrawn-claim `Correction.` bullets was
  caught during T3 by `test-doc-skew-caveat.R` and
  `check-mpl-doc-claims.py` and restored; the scalar-choice change does not
  collide with ADR-054's report-all vectorization (the removed
  `identical(value, choices)` shortcut was a `match.arg` idiom from M2, never
  the report-all mechanism); `rhat`/`ess_bulk` were an omission, not a
  withheld guardrail; the 3.5 floor was a `usethis` scaffold default, never a
  compatibility target, and no 3.5-era workaround code exists in `R/`.
- **[O] diff-bug lens — twelve findings**, ranked below. It separately
  verified clean: the `index` -> `term` rename across ~70 sites (every
  surviving `$index` resolves to an internal field or a locally built frame);
  `man/` and `NAMESPACE` regenerate with zero delta; every new abort branch
  fires classed `intraclass_error` on the right condition; `tidy()`'s
  always-present columns hold on ten fit shapes; `var_residual` keeps one
  meaning across the replicate split; no R 4.1+ syntax or post-4.0 base
  function in shipped code; all five `data-raw/` python checkers exit 0.

### Findings and dispositions

Ranked as the [O] lens ranked them. "Reproduced" marks a finding this review
re-ran against the implementation rather than accepting the reviewer's account.

- **F1 — `glance()$n_o` is `NA` on a nested Design 2 replicate fit, the exact
  shape the column was added to disambiguate.** `R/icc.R:2497` stores
  `design_info$n_o` from `summarize_design()`, which requires
  `n_cells == ns * nr` (`R/design.R:48-51`) and so returns `NA_integer_` for a
  block-diagonal design; the fit itself uses the design-aware `n_o_val`
  (`R/icc.R:1430`), and the comment at `R/icc.R:1368-1370` states the nested
  case is overridden below. **Reproduced** on a 5x6x3x2 nested fit:
  `var_subject_rater` 0.0180, `var_residual` 0.5299, `n_o` `NA`, with
  `tidy()$occasions` showing 1 and 2. The row contradicts itself, and
  falsifies `?icc` ("the occasion count") and `NEWS.md:353` ("both `NA`
  without within-cell replicates"). Crossed Design 1 replicates are correct.
  *Disposition: fix now.*
- **F2 — `NEWS.md:403` promises validation the package does not have, and
  `d_study()` still does the thing D-035 clause 1 abolished.** The bullet
  reads "`mc_samples`, `boot_samples`, `conf_level` and `seed` are validated
  with classed errors in both `icc()` and `d_study()`". **Reproduced:**
  `d_study()` has no `boot_samples` argument (`formals()`: `x, m, n_o,
  conf_level, mc_samples, seed`); `d_study(f, m = 1:3, seed = c(1, 2))`
  succeeds silently on the first element, where `icc(seed = c(1, 2))` aborts
  `intraclass_error`; `d_study(f, m = 1:3, seed = "abc")` emits a base
  coercion warning and then a bare `simpleError`, which is a violation of the
  repo's classed-condition rule. *Disposition: fix now.*
- **F3 — a shipped vignette teaches the access pattern this release declares
  internal.** `R/icc.R:661-668` now names `$estimates`, `$components`,
  `$design`, `$ci`, `$n`, `$mc` as internal; **reproduced by grep**,
  `vignettes/comparison-with-other-packages.Rmd:62,114,160-162` uses
  `$estimates$estimate[1]`, `$n$subjects`, `$n$obs`. The `index` -> `term`
  sweep reached four vignettes and not this one. README and `@examples` are
  clean. *Disposition: fix now.*
- **F4 — the `@return` internal enumeration reads as an allow-list.**
  `R/icc.R:665-667` lists six internal elements and omits `$engine`,
  `$k_eff`, `$k_c_eff`, `$boot`, which the object also carries
  (`R/icc.R:2500-2567`). The sentence says "Everything else in the list is
  internal", so the list is meant as illustration, but a boundary being frozen
  at a one-way door should not leave four names readable as public.
  *Disposition: fix now.*
- **F5 — `occasions` is a fourth report-all argument that D-035, NEWS and the
  code comment all omit.** `NEWS.md:365` says the arguments that genuinely
  take several values are "(`type`, `unit`, `level`)"; the comment at
  `R/icc.R:2597-2600` says the same. **Reproduced:**
  `icc(..., occasions = c("single", "average"))` returns 8 rows. A user reading
  NEWS would conclude that call aborts. *Disposition: fix now* for `NEWS.md`
  and the code comment; `DECISIONS.md` is append-only, so D-035 takes an
  annotating entry rather than an edit.
- **F6 — AC7's structural gap, and `cran-comments.md` lists environments this
  code has not run on.** The AC7 half is the amendment return recorded above.
  The second half: `cran-comments.md` "Test environments" lists ubuntu
  R-devel / R-oldrel-1 and macOS-release, none of which has run against this
  branch, and nothing anywhere exercises the newly declared `R (>= 4.0.0)`
  floor — the floor is a dependency-chain inference (which the lens
  independently re-derived as correct: rlang 1.3.0 `Depends: R (>= 4.0.0)`,
  every other Import lower). A CRAN reviewer reads that section as where the
  package was checked. *Disposition: fix now* (state what has run and what is
  scheduled), coupled to the AC7 amendment.
- **F7 — `cairn/ROADMAP.md:41` still reasons from the floor this diff
  retired.** The M104-hardening candidate row calls `identical(cell$arm,
  "zero-between")` "a factor comparison under the declared `R (>= 3.5)`
  floor"; at `R >= 4.0.0` `stringsAsFactors` defaults `FALSE`, so `cell$arm`
  is character and the described failure cannot occur. **Reproduced by grep**;
  the DESCRIPTION change that retired the premise is in this same diff.
  *Disposition: fix now* — ROADMAP is current knowledge, corrected in place
  and marked.
- **F8 — the record-claims ledger asserts three figures at a citation that
  now carries one.** `data-raw/record-claims.tsv:5` registers
  `kappa-worst-steps` with claim text naming -0.046 at 0.90, -0.068 at 0.95
  and -0.162 at 0.99, scope `cairn/ROADMAP.md`; the compressed row
  (`cairn/ROADMAP.md:44`) states only the 0.95 figure. **Reproduced by
  reading both.** `check-record-claims.py` exits 0 because the `presence`
  kind checks only the `[claim:...]` citation and a green re-derivation, never
  the ledger text against the record. *Disposition: follow-up* — the checker
  gap is a guard over the repo's own records, D-021 territory; the row itself
  is accurate as far as it goes.
- **F9 — doc prose still describes the pre-rename, conditional-column
  behaviour.** `R/d-study.R:54,73` (-> `man/d_study.Rd:134,155`) say the
  result "gains a `level` column" / "gains an `occasions` column";
  `vignettes/d-studies-and-replicates.Rmd:75` says "adding a `type` column";
  `man/d_study.Rd:58` still names the object's `index` column, the one
  surviving `index` on an exported doc page. True of the object, but the same
  `@return` now points readers at `tidy()`, where nothing is ever gained.
  *Disposition: fix now.*
- **F10 — the new columns have no positive test on the shapes that populate
  them.** `rhat`/`ess_bulk` are pinned only in the all-`NA` non-Bayesian case
  (`test-exported-contract.R:161-168`); `tidy.icc_dstudy` only where
  `occasions` and `level` are both `NA` (`:152-155`). Nothing asserts they
  fill. F1 would have been caught by a nested-replicate case in the `glance`
  test. *Disposition: fix now* for the `d_study` fill cases and a nested
  replicate `glance` case (both cheap, no Bayesian engine needed); the
  populated-`rhat` assertion on a real `brms` fit goes *follow-up*, being a
  slow Suggests-gated fit.
- **F11 — `glance()` still cannot disambiguate `var_rater`.** On a
  `raters = "fixed"` fit `var_rater` holds the finite-population theta^2_r,
  indistinguishable in the row from a random fit; a one-way and a Design-3 fit
  both fold rater variance into `var_residual`. So `NEWS.md:353-356`'s "which
  quantity the residual holds is readable from the row" is true of the
  replicate axis only. Not a regression; the shipped fix is narrower than the
  sentence describing it. *Disposition: fix now* — narrow the NEWS sentence.
- **F12 — minor bag, reported for completeness.** `tidy()$occasions` is `int`
  on a non-replicate fit and `dbl` on a replicate one (row-binds cleanly;
  cosmetic). `R/icc.R:2529`'s comment says `posterior_summary` is surfaced in
  `glance()`; it is not (pre-existing). `R/d-study.R:687-688`'s comment
  mis-attributes the `$`-warning to data frames rather than tibbles.
  `inst/WORDLIST` was re-sorted case-insensitively, so the next
  `update_wordlist()` will produce a whole-file diff. Two `data-raw/reviews/`
  scripts use 4.1+/4.2 syntax — not shipped (`^data-raw$` is
  `.Rbuildignore`d) and above the floor anyway. The T3 work-log line's NEWS
  figures are wrong: it says 796 -> 407 lines; **reproduced**, the real
  numbers are 770 (`origin/main`) -> 409 at `9b11e9e` -> 429 now, after the
  T3 follow-up restored the skew-caveat and MPL anchors. `cairn/DESIGN.md:53`
  says the commitment is "R release, oldrel-1, and devel on
  macOS/Windows/Ubuntu"; devel and oldrel-1 run on Ubuntu only.
  *Disposition: fix now* for the comment corrections, the DESIGN.md sentence
  and a superseding work-log line carrying the true NEWS figures; the
  `int`/`dbl` nit and the WORDLIST sort order are *rejected as cosmetic*, and
  the `data-raw/reviews/` syntax note is *rejected as out of scope* (not
  shipped, and the T2 claim was accurate as scoped).
