# M98: Assert the endpoint-parity test's clamp-detection classes, and add the non-finite one

**Status:** done (2026-08-01, PR #106 https://github.com/jmgirard/intraclass/pull/106)

**Goal:** Make the AC4 endpoint-parity test's ability to detect post-processing
in `icc()`'s reporting path asserted per clamp class, not incidental.

**Outcome:** Per-class census flags (`seen_finite_below_neg1`, `seen_nonfinite`)
asserted separately after the AC4 grid loop in `test-boundary-abort-hint.R`; a
seed-free SSA = 0 `searle` case (`bh_degen_between()`, units single/average/2 →
−0.5/−Inf/−2) supplies the previously uncovered non-finite class and a seed-free
second finite-below-−1 supplier; count literals 26/25. Comment ledger fully
measured: `pmax(0, .)` reds 13 cells post / 10 pre (min finite conf.low
−2.533756); `pmax(-1, .)` reds 3 incl. the −Inf cell; non-finite-only clamp at
the reporting assembly 0 → 1 failures pre → post. Test-only; high-side
(`pmin(1, .)`) detection stays a ROADMAP candidate.

**Decisions:** none promoted; plan-gate choices (seed-free cell over injected
endpoint, per-class over combined assertion) live in the work log.

**Review:** Return 1 — AC5 failed on a carried, unmeasured `pmax(0, .)` figure
(F4, 82); fixed by per-cell re-measurement. Pass 2: three lenses + scorer, no
finding ≥ 80, 15 logged (highest DB5, 62). LESSONS gained the
testthat max_fails-censoring line; nothing retired.
