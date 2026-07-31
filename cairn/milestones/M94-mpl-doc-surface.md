# M94: Exported documentation of the MPL interpolation evidence, with a fixture-reading check

- **Status:** review
- **Branch:** m94-mpl-doc-surface
- **PR:** https://github.com/jmgirard/intraclass/pull/101
- **Priority:** normal
- **Depends on:** M92
- **Driving RR:** —
- **Principles touched:** GP1, GP7

## Goal

Tell users what M92 measured about `ci_method = "mpl"` — in `@param` and NEWS — under a
committed check that fails when a documented claim stops being true of the fixture.

## Scope

**In:** the exported prose surface M92's re-cut fenced out — `@param ci_method` and
`@param conf_level` in `R/icc.R`, the regenerated `man/`, and a `NEWS.md` entry:
that the interpolated-subject-count path is coverage-checked at each supported level,
and what the validated cells do and do not license about the interval's asymmetry. Plus
the enforcement that makes those claims safe: a committed script that reads
`data-raw/m92-interp-sweep.rds`, settles every universal/negative claim the docs make
about the cells, and runs in CI.

**Out:** re-running or re-calibrating anything — M92's fixtures are frozen inputs here ·
the `interval-methods.Rmd` vignette treatment of all four opt-in `ci_method` values →
stays its own ROADMAP candidate (a method-wide writing job, not this `@param` pass) ·
any change to `mpl_kappa_lookup` or the κ_m table → M92 settled that, D-015 · claims
about 0.90/0.99, which M91 already documents.

## Acceptance criteria

- [x] AC1 (GP1): `@param ci_method` states that the constant is interpolated between
      subject nodes and that the interpolated path is coverage-checked at each
      supported level, in language an applied reader can act on — and says plainly what
      it does not establish (nodes are individually calibrated; interpolated values are
      validated at a handful of geometries, not calibrated).
- [x] AC2 (GP7, the M71 lesson made mechanical): every **universal or negative** claim
      the exported docs make about M92's validated cells — "no cell…", "the cells
      differ in…", "every cell…", "nothing isolates…" — is listed in a committed ledger
      with the assertion that settles it.
- [x] AC3: `data-raw/check-mpl-doc-claims.py` reads `data-raw/m92-interp-sweep.rds`,
      evaluates every ledger assertion, and exits non-zero when any fails. A claim in
      the docs with no ledger row, or a ledger row with no claim, also fails it.
- [x] AC4: the check is mutation-verified — inverting each documented claim in turn, and
      separately pointing the script at the superseded
      `data-raw/m92-interp-sweep-run1-collided.rds`, each make it exit non-zero. A
      by-hand record of the inversions is committed if no automated harness fits.
- [x] AC5: the check runs in CI, not only locally — `cairn_validate` does not cover
      `data-raw/` checkers, so a locally-green consistency gate can still ship a false
      doc claim (M85).
- [x] AC6: the specific claim M92's review found false is settled, not repeated: **E2
      and E3 differ only in rater count** (`n_s` 40, `delta` 4, `rho` 0.60, `conf` 0.95;
      `n_r` 10 vs 2), so any "nothing isolates the rater axis" wording is refused by the
      check. Whatever the docs say about asymmetry across raters carries its own row.
- [x] AC7: `devtools::check()`, `devtools::test()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; `pkgdown::check_pkgdown()`
      clean; the references-CI checkers green; and `NEWS.md` carries the user-facing entry.

## Coverage

- AC1 → T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T1, T3
- AC7 → T5

## Tasks

- [x] T1: Enumerate, from `data-raw/m92-interp-sweep.rds`, what the cells actually
      license — including which pairs vary in one factor alone — and draft the claim
      ledger from that, before writing any prose. Reversing this order is how M92's
      P3-1 was written.
- [x] T2: Write the `@param ci_method` / `@param conf_level` text and the `NEWS.md`
      entry against the ledger; `devtools::document()`.
- [x] T3: Implement `data-raw/check-mpl-doc-claims.py` — parse the ledger, evaluate each
      assertion against the fixture, and cross-check ledger↔docs both ways.
- [x] T4: Mutation-verify: invert each claim in turn, and point the script at the
      collided fixture; record that each reds.
- [x] T5: Wire the check into the CI job that already runs the references checkers, run
      the full gate, open the PR.

## Work log

- 2026-07-25: created by /milestone-plan as the second half of M92's re-cut (M92 failed review three times, every failure in this exported prose surface; the thrash rule sent it back to plan). The rule this milestone exists to enforce — a universal or negative claim about the repo's own fixture must carry the command that settles it — is `cairn/LESSONS.md:30` (M71), which until now had no enforcement on the roxygen surface.

- 2026-07-31: T1 done — fixture enumerated (single single-factor pair: E2 vs E3, n_r only; all cells δ=4/ρ=0.60/0.95; floors clear at min 0.944; miss direction non-uniform: 31/2, 42/14, 0/1; no endpoint saturation); ledger drafted at `data-raw/mpl-doc-claims.tsv` (9 settle + 1 absent row, keys recomputed at T3). Gate choices: stdlib RDS parser in-script (no new dep), committed TSV ledger.

- 2026-07-31: T2 done — interpolation paragraph added to `@param ci_method`, one sentence to `@param conf_level`, NEWS bullet added (no milestone numbers, per tracking rules); every ledger quote appears verbatim; `devtools::document()` clean, `man/icc.Rd` regenerated.

- 2026-07-31: T3 done — checker implemented with a stdlib-only RDS reader (no R, no pip in the R-free CI job); wide-recall sentence enumerator over the two `@param` blocks + the NEWS bullet found 30 candidates; ledger finalized (12 settle, 2 absent AC6-refusal, 21 out rows); check green both directions.

- 2026-07-31: T4 done — mutation verification is the automated `--self-test` (no by-hand record needed): inverting each of the 12 settle assertions reds, deleting each settled claim sentence from the docs reds, injecting the refused rater-axis wording reds, an unledgered universal reds, and the collided run-1 fixture reds on exactly the three number-citing rows (0.944; 31/2 and 42/14; E3 missed once, above).

- 2026-07-31: T5 done — check + its self-test wired into lint.yaml's R-free `check-references` job; full gate green: `devtools::test()` (NOT_CRAN=true CI=true) 0 fail/0 error/5106 pass, `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0/0/0, `lintr::lint_package()` 0 lints, `air format --check` clean, `devtools::document()` no-diff, `pkgdown::check_pkgdown()` clean, all references-CI checkers green. Status → review, PR opened.

- 2026-07-31: merge gate — approved as "fix 3 items, then merge": O-12 empty-quote guard and O-13 unknown-file guard added to the checker (both verified fail-closed by mutation), O-7's false ledger reason corrected (test-ci-mpl.R pins spot values only; whole-table pin is M95). Checker, self-test, air, lintr re-run green; no R surface touched.

## Decisions

## Review

### Acceptance-criteria evidence (2026-07-31, review session, HEAD = branch tip)

- AC1: `@param ci_method` (R/icc.R:363–382 block) states node calibration, linear-in-S
  interpolation, validated-not-calibrated, the three 0.95 cells with their single stress
  configuration, the floor-as-tolerance (0.944), no endpoint pinning, and non-uniform
  asymmetry direction; `@param conf_level` adds the per-level coverage-checked sentence.
  `man/icc.Rd` regenerated, `devtools::document()` no-diff at review.
- AC2: `data-raw/mpl-doc-claims.tsv` — 30 enumerated candidates, 12 settle rows with
  assertions, 2 absent (refusal) rows, 21 out rows with reasons; checker cross-checks
  ledger↔docs both ways, exit 0.
- AC3: `python3 data-raw/check-mpl-doc-claims.py` exit 0 on the live fixture; exit 1 on
  the collided fixture; self-test confirms a claim-with-no-row and a row-with-no-claim
  each red (steps 3 and 5 of --self-test).
- AC4: `--self-test` exit 0 — inverting each of the 12 settle assertions reds, deleting
  each settled claim sentence reds, injecting the refused rater-axis wording reds, and
  the collided run-1 fixture reds on exactly the three number-citing rows. Automated
  harness, so no by-hand record needed.
- AC5: PR #101 CI job `check-references` green with both new steps executed
  ("Check MPL doc claims against the M92 fixture (M94)" ✓, "Self-test the MPL
  doc-claims check (mutation harness)" ✓, run 30670979045).
- AC6: ledger row keyed f80587033837 asserts the E2/E3 pair differs only in `n_r`
  (10 vs 2, all else equal) and that the miss direction flips; two `absent` rows refuse
  any "nothing isolates the rater axis" wording on both doc surfaces; self-test
  injection of that wording reds.
- AC7: this session, by command: `devtools::test()` (NOT_CRAN=true CI=true) 0 fail /
  0 error / 5106 pass; `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors /
  0 warnings / 0 notes; `lintr::lint_package()` 0 lints; `air format --check` clean;
  `devtools::document()` no-diff; `pkgdown::check_pkgdown()` clean; all four
  references-CI checkers + the new check and self-test green; NEWS.md entry present
  (no milestone numbers). `cairn_validate` exit 0 (pre-existing dangling-id WARN only);
  README.Rmd/README.md untouched by this milestone.

### Independent review (2026-07-31): three lenses + scorer — 0 findings ≥ 80

Driving RR: none → projection-vs-outcome no-ops. [O] diff-bug lens: 33 candidates
(4 reproduced by execution; its numeric re-verification of every doc figure against the
fixture found all correct, and man/icc.Rd byte-identical to fresh roxygenise). [S]
blame-history lens: 0 defects (M91/M93 wording untouched, D-009/M74 CI steps
byte-identical, NEWS conventions held) + 1 out-of-scope advisory (pre-M94 D-015
"bilinear" wording). [S] prior-PR lens: 3 possible regressions, 4 explicit
no-regressions (P3-1's forbidden wording confirmed guarded by the two absent rows).
[S] scorer (rubric verbatim, diff + milestone file in hand): **no finding ≥ 80 —
actioned list empty**. Sub-80 log (37 scored; one line each, top scores first):
O-12 (72) empty-quote ledger row would fail open — reproduced; O-13 (72) absent row
with a misspelled file value fails open — reproduced; O-26 (65) every-level wording
vs the Out fence — but AC1 itself mandates "coverage-checked at each supported
level", so plan-mandated; O-7 (60) the b4fbd95986f0 out-row reason overstates what
test-ci-mpl.R pins (node list is not spot-pinned there); O-1 (55) "handful" loose
for the single 0.90 interp cell; O-15 (55) self-test injects a literal, not the
row's own regex; P-3 (55) three-cell framing of the across-raters sentence (ledger
correctly scopes to E2/E3); P-2 (50) 0.90/0.99 legs rest on M91's fixture, not this
checker (disclosed in reason columns); O-29 (50) NEWS points at an Rbuildignored
path; O-2 (45, scorer note: D4 is a node-sitting subgrid-ρ probe, not an interp
cell, so the paragraph's universal holds on its own set); O-10 (45) trigger net
lacks differ/same/isolat*; O-23 (45) three settle rows settle the 0.95 leg only
(disclosed); O-4 (40) direction flip rests on E3's single miss (doc states it as
observed fact); O-14 (35) 9 of 12 assertions insensitive to the collided fixture
(structural facts; documented); O-16 (35) inversion harness can't catch a tautology;
O-24 (35) reason text unvalidated; P-6 (30) NEWS "settled mechanically" scoped to
the validated cells by its own wording; O-6 (30) floor clearance is point-estimate
framing; O-17 (30) unledgered-claim probe hits NEWS scope only; O-22 (30) news_scope
truncates at first blank line; B-7/O-5/O-8/O-9/O-18/O-19/O-21/O-25/O-28/O-31/O-32
(20–25) hypothetical robustness, misreadings, or pre-existing; P-1 (25) restating
figures is the planned change, now CI-enforced; O-3 (20) width point pre-empted by
the doc's own carry-nothing sentence; O-20 (15) scope net matches the plan's In
fence; O-33 (15) parser future-proofing; O-30 (10) WORDLIST nit; O-11 (5) claimed
repro false — scorer re-ran it and the checker reds with a stale-key error.
