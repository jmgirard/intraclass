# M88: Exported profile-likelihood `ci_method = "mpl"` — two-way random ICC(A,1)/ICC(A,k)

- **Status:** review
- **Priority:** normal
- **Depends on:** M86, M87
- **Driving RR:** —
- **Principles touched:** IP1, GP2, GP7
- **Branch/PR:** m88-mpl-ci-method · https://github.com/jmgirard/intraclass/pull/95

## Goal

Export the M86/M87-validated modified-profile-likelihood interval as an opt-in
`ci_method = "mpl"` for the balanced-complete two-way random ICC(A,1) (and ICC(A,k)
by Spearman-Brown inheritance), per the D-014 GO-for-opt-in.

## Scope

**In:** port the deterministic MPL interval machinery (`data-raw/m86-mpl-lib.R`) into
`R/ci-mpl.R`; ship a seeded precomputed κ_m table (`R/sysdata.rda`) with lookup +
bilinear interpolation; wire `ci_method = "mpl"` into `icc()` for the two-way random
absolute-agreement cell, `unit = "single"` (ICC(A,1)) and `"average"` (ICC(A,k) via
the shared `npb_sb()` SB map). Point = engine (glmmTMB REML) point; deterministic
(no draws/SE), mirroring `"searle"`/`"burch"` (D-013).

**Out:** on-the-fly κ_m calibration (κ_m is table-only) → candidate; numeric `unit`
(D-study projection to m≠R raters) → candidate; consistency ICC(C,·), fixed raters,
one-way/cluster/multilevel designs, unbalanced/incomplete data, non-Gaussian — all
abort loudly (#5), each unchanged by this milestone; a classical boundary-robust
two-way *default* (contract change) stays the separate `#3` candidate.

## Acceptance criteria

- [x] AC1: The ported MPL interval core in `R/ci-mpl.R` reproduces the xiao2013
      Example 1 worked example deterministically in `test-ci-mpl.R` (p. 2255:
      ρ̂ = 0.8987; naive-PL 90% two-sided (0.7120, 0.9598); 95% one-sided lower
      0.7120), establishing the likelihood/deviance/interval machinery (IP1; #1). The
      MC coverage/κ_m Tables 3/4/6/7 remain established by the committed M86 offline
      harness (`data-raw/m86-mpl-validate.R` + `.rds`), which a fast suite cannot re-run.
- [x] AC2: `icc(x, model="twoway", raters="random", type="agreement", unit="single",
      ci_method="mpl")` on balanced-complete Gaussian data returns a finite interval
      whose point is the engine (glmmTMB REML) point, with `std.error = NA`,
      `ci$samples = NA`, and a `print()` label naming a modified-profile-likelihood
      interval (D-013 conventions).
- [x] AC3: `unit="average"` returns `npb_sb()` applied to the ICC(A,1) MPL endpoints;
      a committed cross-check asserts endpoint-equality to the exact Spearman-Brown
      image (divisor R), recomputed independently of the package's `npb_sb`, and
      mutation-proves divergence under a wrong divisor (D-013 Burch precedent — MPL has
      no independent direct ICC(A,k) construction, so ICC(A,k) is inheritance, not an
      anchor; M82 anti-tautology lesson). ORACLES basis = inheritance.
- [x] AC4: κ_m is supplied from the shipped table by lookup + bilinear interpolation
      within the (R,S) grid; an off-grid (R,S) and every out-of-scope estimand
      (consistency, fixed raters, non-two-way, unbalanced/incomplete, numeric `unit`)
      aborts with a classed `intraclass_*` error naming the supported cell (#5/#8).
- [x] AC5: On a near-zero-ρ boundary cell where the two-way random Monte-Carlo
      default aborts (`intraclass_singular_fit`), `ci_method="mpl"` returns an
      interval — the M87/D-014 residual-value behavior — asserted in the suite.
- [x] AC6: `@param ci_method` documents `"mpl"` and carries D-014 conditions (i) the
      sub-ρ=0.6 κ_m is oracle-less (simulated-coverage basis only) and (iii)
      balanced-complete + Gaussian only; the κ_m table's seeded provenance is recorded.
- [x] AC7: Gates clean — profile `verify` (test + lint), `air format --check`, and the
      `check-references` generalizing-claims + reference-observations gates (xiao2013
      exclude directives updated for any new `data-raw/` file; M85/M86 lessons).

## Coverage

- AC1 → T1, T2
- AC2 → T1, T6
- AC3 → T5
- AC4 → T3, T4, T6
- AC5 → T6, T7
- AC6 → T8
- AC7 → T8, T9

## Tasks

- [x] T1: Port `mpl_matrix/anova/neg2l/prof_neg2l/fit/deviance/interval` from
      `data-raw/m86-mpl-lib.R` into `R/ci-mpl.R` (deterministic interval machinery;
      classed aborts; lint-clean snake_case). The `mpl_ci()` reducer + κ_m lookup
      land with T4/T5/T6.
- [x] T2: xiao2013 Example 1 deterministic oracle in `tests/testthat/test-ci-mpl.R`
      (AC1, gate-amended; point + endpoints, honest rounding tolerance on the lower).
- [x] T3: Author the seeded κ_m table generator in `data-raw/` — per-geometry full
      (ρ∈[0.05,0.9] × δ=2^-1..4) scan to LOCATE the argmax, then bias-corrected
      re-evaluation of the top-3 cells (max) at high n_mc (M87 T2's method; the argmax
      is NOT universally the corner — it varies with R, so it must be found). Grid
      R=2:10 × S∈{10,15,20,30,50,100}; background job (~2–2.5 h); commit to
      `R/sysdata.rda`. Built-in cross-check vs M87's committed κ_m.
- [x] T4: κ_m lookup + bilinear interpolation over the grid; off-grid (R,S) aborts
      loudly (#5/#8) rather than extrapolating an uncalibrated κ_m.
- [x] T5: ICC(A,k) via the shared `npb_sb()` image of the ICC(A,1) endpoints, plus the
      committed SB-inheritance identity + wrong-divisor mutation cross-check (the SB map
      recomputed independently of the package's `npb_sb`; inheritance, not an anchor).
- [x] T6: Wire `"mpl"` into `icc()` — add to the `ci_method` vocabulary
      (`R/icc.R:503`), add the two-way-random-agreement guard (counterpart of the
      one-way guard at `R/icc.R:1334`), add the dispatch branch (mirror `searle_ci`
      at `R/icc.R:1966`), set samples/std.error `NA` + the print label.
- [x] T7: Boundary-behavior test — `ci_method="mpl"` returns an interval on a cell
      where the two-way MC default aborts (`test-ci-mpl.R`).
- [x] T8: Docs + references — `@param ci_method`, D-014 conditions (i)/(iii), κ_m
      provenance; update `references/mpl-twoway-random-comparison.md`, add any
      generalizing-claims triage rows, and append `xiao2013.md` exclude directives for
      the new `data-raw/` generator (M85/M86 lessons; `_pkgdown.yml` if a new export).
- [x] T9: Full gate — `devtools::check` at CI parity (`NOT_CRAN` per the profile),
      `lintr::lint_package()`, `air format --check`, and `check-references` locally.

## Work log

- 2026-07-23: created by /milestone-plan. Scope settled by D-015 — precomputed κ_m table, ICC(A,k) via `npb_sb()` SB inheritance (exact event identity, no new oracle), name `"mpl"`.
- 2026-07-23: set in-progress; branched m88-mpl-ci-method.
- 2026-07-23: AC1 amended (gate-approved) — deterministic xiao2013 Example 1 is the in-suite oracle; MC coverage/κ_m Tables 3/4/6/7 stay the committed M86 offline harness (a fast suite can't re-run them). Mirrors the searle/burch sibling pattern; coverage map unchanged.
- 2026-07-23: T1+T2 — ported deterministic MPL core to `R/ci-mpl.R`; Example 1 oracle in `test-ci-mpl.R` (point ρ̂=0.8987 to 1e-3, upper 0.9598 to 5e-3, lower 0.7120 to 1.5e-2 — published inputs are rounded, #4). CI-parity suite clean (4052 pass, 0 fail). Fence detail: `mpl` will support two-sided conf_level=0.95 (the M87 recalibration level); other levels abort (T6).
- 2026-07-23: T3 method correction — a first generator assumed the κ_corr argmax was the (ρ=0.05, δ=16) corner (M86/M87 established that only for R∈{3,5}). An argmax probe falsified it: (2,10)→(0.30,16), (10,10)→(0.90,0.5), (10,100)→(0.60,16). Corner-direct would under-estimate κ_m → under-coverage. Rewrote to M87 T2's per-geometry scan + top-3 re-eval (max), ~2–2.5 h background job; relaunched.
- 2026-07-23: T6 wired — `"mpl"` in the ci_method vocabulary + two-way-random-agreement fence guard + dispatch branch + samples=NA metadata + `print()` label "modified profile likelihood". T4/T5 authored (κ_m lookup + `mpl_ci` reducer). Fence detail: `type` defaults to agreement+consistency, so mpl narrows an UNSET type to agreement but aborts an EXPLICIT consistency request (agreement-only method).
- 2026-07-23: T8 references done — O-MPL registered in ORACLES.md; xiao2013.md/xiao2009.md "traces"/orphan claims updated (paper now exported, not prototype-only; xiao2009 grep narrowed to its own citekey to avoid xiao2013 conflation); mpl-twoway-comparison.md export note; O-MPL decision triage row. Both `check-references` gates green.
- 2026-07-23: HONEST CHECKPOINT — R wiring + reducer + refs committed; `devtools::load_all` clean, AC1 (deterministic Example 1) 0 failures. T3 κ_m table still generating (~2 h); AC2–AC5 end-to-end tests + T9 gate + `document()` pending its completion (they currently error only on the not-yet-built `kappa_m_table`). Tasks T3–T7 stay unchecked until verified end-to-end.
- 2026-07-24: T3 table complete (54 nodes, `R/sysdata.rda`) — M87 cross-check ALL PASS (4 shared geometries, |Δ| ≤ 0.045). T4–T7 verified: full `test-ci-mpl.R` 31 pass (AC2 engine-point/metadata/print label, AC3 SB identity + wrong-divisor mutation, AC4 fence + off-grid aborts, AC5 interval where MC aborts). T9 gate clean: CI-parity suite 4072 pass / 0 fail; `R CMD check` 0/0/0; `lintr::lint_package` 0; `air --check` clean; both `check-references` gates green; `document()` regenerated `icc.Rd`. Note for review: κ_m is small + argmax-noisy at high R (R≥8, κ_m≈0.08–0.19), a region beyond M87's validated cells — low-impact (small correction) but un-oracled, per the D-014 (i) caveat. All tasks done → review.
- 2026-07-24: review — opened draft PR #95; added NEWS.md entry for `ci_method="mpl"`. AC3 wording amended at the review gate (gate-approved): it asked for a "direct McGraw-Wong ICC(A,k) form from raw statistics", but MPL (likelihood-based) has no independent direct ICC(A,k) construction — corrected to the exact SB-inheritance identity + wrong-divisor mutation (D-013 Burch precedent); shipped test already matches (no code change). T5 task text aligned.
- 2026-07-24: 3-lens review + scorer — 2 findings actioned: fence now aborts within-cell-replicated designs (score 96; was returning a mis-calibrated interval, AC4/#5) and the consistency-drop now emits a `cli_inform` (score 87; ADR-054/ADR-029 convention). 1 finding logged below-bar (score 74, inverted κ_m-interpolation comment) but corrected as a known-false comment. 2 regression tests added. Post-fix: full suite 4074 pass / 0 fail, lintr 0, air clean.

## Decisions

## Review

**AC evidence** (fresh, `test-ci-mpl.R` + gate commands, 2026-07-24; PR #95):

- **AC1** ✓ — `test-ci-mpl.R` "MPL core reproduces xiao2013 Example 1" (5 pass): ρ̂
  to 1e-3, upper 0.9598 to 5e-3, lower 0.7120 to 1.5e-2 (rounded inputs, #4); plus
  interval-ordered (4) + `mpl_matrix` (2). MC Tables 3/4/6/7 = committed M86 offline.
- **AC2** ✓ — "engine REML point + deterministic metadata" (9 pass): `ci$method="mpl"`,
  `samples`/`std.error` NA, point == montecarlo point (1e-8), finite ordered interval
  in [0,1], `format()` header names "modified profile likelihood".
- **AC3** (gate-amended) ✓ — "ICC(A,k) is the exact Spearman-Brown image, divisor R"
  (3 pass): `ik == sb(i1, R)` to 1e-9 (SB recomputed independently), wrong divisor
  R+1 diverges. Inheritance, no independent anchor (D-013 Burch).
- **AC4** ✓ — fence aborts (5) + unbalanced/off-grid aborts (2): one-way, explicit
  consistency, fixed raters, numeric `unit`, `conf_level≠0.95`, incomplete, and S=6
  off-grid all raise `intraclass_unsupported`.
- **AC5** ✓ — "interval where the two-way MC default aborts" (1 pass): a boundary
  dataset that aborts MC (`intraclass_singular_fit`) yields a finite MPL interval.
- **AC6** ✓ — `@param ci_method` (regenerated `man/icc.Rd`) documents `"mpl"` + opt-in,
  Gaussian, `conf_level = 0.95`, and the sub-0.6 "no external oracle" caveat; κ_m
  provenance recorded in `ORACLES.md` O-MPL + the seeded generator.
- **AC7** ✓ — CI-parity suite 4072 pass / 0 fail; `lintr::lint_package` 0; `air --check`
  clean; both `check-references` gates green.

**Consistency gate:** `cairn_validate` exit 0; `devtools::document()` no diff;
`pkgdown::check_pkgdown()` clean; `R CMD check` 0 errors / 0 warnings / 0 notes
(manual PDF skipped — known TinyTeX Courier infra issue, not code); NEWS.md entry
added; no new top-level files; no DESIGN.md principle text changed (IP1/GP2/GP7
worked-under, not modified) → `cairn_impact` n/a. No Driving RR → projection check n/a.

**Independent review — 3 lenses (diff-bug [O], blame-history [S], prior-review [S]) + scorer [S]:**

- **Finding [diff-bug] — score 96 — FIXED.** The mpl fence did not exclude within-cell
  **replicated** designs: a balanced replicated two-way design (`balanced==TRUE`) passed
  the fence, `mpl_matrix` collapsed replicates to cell means, and the interval bracketed
  a different estimand than the reported point (conf.low > point observed). Violated AC4
  / #5. Fixed: added `|| replicates` to the fence guard (`R/icc.R`); regression test
  "mpl aborts on a within-cell-replicated two-way design" (`test-ci-mpl.R`).
- **Finding [blame-history] — score 87 — FIXED.** The mpl `type`-narrowing dropped
  `consistency` from a defaulted `type` **silently**, breaking the ADR-054/ADR-029
  drop-vs-abort convention (every other narrowing site emits `cli::cli_inform`). Fixed:
  added the `cli::cli_inform("Dropping {.val consistency}: …")` message (`R/icc.R`);
  regression test "mpl informs when it drops consistency from a defaulted type".
- **Finding [diff-bug] — score 74 — below the action bar; corrected opportunistically.**
  The `mpl_kappa_lookup` comment claimed κ_m(S) is convex-decreasing (linear interp
  over-estimates → conservative); the table is increasing/concave (matching xiao2013),
  so interp mildly under-estimates. A non-exported comment, no shipped value affected —
  but a known-false statement, so the comment was corrected (`R/ci-mpl.R`).
- **[prior-review] — no findings** (M82 anti-tautology lesson honored, references-gate
  directives correct, GitHub probe empty).

Post-fix: `test-ci-mpl.R` 33 pass; full CI-parity suite 4074 pass / 0 fail; `lintr` 0;
`air --check` clean.
