# M107: Oracle-script reproducibility — the re-run harness and the first sixteen re-runs

**Status:** done (2026-08-07, [PR #116](https://github.com/jmgirard/intraclass/pull/116))

**Goal:** Establish whether the seeded oracle scripts still reproduce their
committed values: a compare-don't-overwrite re-run harness under a pre-declared
divergence policy, run over the 15 non-Bayes scripts plus `oracle-bayesian.R`.

**Outcome:** `data-raw/rerun-oracle.R` (non-fatal `stopifnot` recorder; `saveRDS`
+ checkpoint-I/O redirected to tempdir; NA-aware leaf compare; engine versions
per run) + the 16-row `data-raw/oracle-rerun-ledger.tsv`: 4 reproduced (3 at
delta 0), 9 pins-pass, 1 drift-within-noise (annotated comparator artifact),
2 escalations — `oracle-bayesian.R` convergence guard (k=2 fresh .864 vs ≥.90,
fixture .904; published-findings pins hold; → candidate row) and
`oracle-incomplete.R`'s stale one-row `tidy()` pin (fixed post-merge). Five
legacy scripts now write fixture-before-pins; O-Bayes ORACLES entry corrected
to the observed run; no committed fixture modified.

**Decisions:** D-024 (divergence policy — pins are the bar; escalate, never re-baseline); none milestone-local.

**Review:** 3 lenses + scorer, 38 candidates, 5 actioned ≥80 all fixed on-branch
(D-024 id qualification 92; stranded `Wrote` message 88; README save-first false
universal 85; checkpoint self-certification risk 82; comparator
NA-crash/Inf-as-noise 80); 26 logged sub-80 incl. AC5's stale line anchor (52,
accepted at the merge gate); nothing retired.
