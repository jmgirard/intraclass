# M105: Non-finite input and the zero-between-variance Burch interval fail classed, never raw and never silently

**Status:** done (2026-08-05, PR #113 https://github.com/jmgirard/intraclass/pull/113)

**Goal:** Where `icc()` failed with a raw, unclassed error or reported a `NaN` interval — on a non-finite `score`, and on `ci_method = "burch"` at exactly zero between-subject variance — it now raises a classed condition instead; and an `NA` score is dropped and analysed as the incomplete design the package already fits.

**Outcome:** Non-finite `score` (`Inf`/`-Inf`/`NaN`) is refused at canonicalization, before any fit, naming the column and offending rows — previously each engine surfaced its own unclassed error. `burch_ci()` gains a Burch-only `identical(MSA, 0)` guard aborting `intraclass_singular_fit`, replacing a bare `simpleError` from `npb_guard_sb_pole()`'s non-NaN-safe `!any(denom < 0)` at `unit = "average"` and a silently reported NaN interval at `unit = "single"`; kept out of the shared `classical_guard_observed()` because SEARLE has a correct answer on the same data. `NA` scores are dropped with a suppressible `intraclass_dropped_rows` warning and analysed as an incomplete design, which also changes reachable `ci_method` values (the phantom observed cell no longer makes an unbalanced design read as balanced). New: `tests/testthat/fixtures/degenerate-classical-cells.tsv` + its generator, `test-degenerate-classical.R`. Repaired a `record-claims.tsv` row red on main since M104.

**Decisions:** D-022 (all three parts, plus the untouched clause deferring `searle`'s `-Inf` and the exact-pole tolerance to D-010).

**Review:** Three lenses, 22 findings, independent scorer; F6/F21/F22 (80–88) actioned, all stale prose this branch falsified, plus five sub-80 fixed with reasons. Two returns: the Goal was falsified by its own AC4 (re-cut via `/milestone-plan`), then Windows CI failed AC3 because the fixture's `msa_exact_zero` records platform-dependent roundoff. A fourth lens over the fix commit found that fix incomplete — the same claim was still live in `?icc`.
