# M83: Repair rotted `skip_on_ci` brms test expectations + pin explicit `type=`/`level=`

**Status:** done (2026-07-23, PR #90 https://github.com/jmgirard/intraclass/pull/90)

**Goal:** Restore `tests/testthat/test-icc-brms.R` to green under a live-Stan run and pin its fits' `type=`/`level=` explicitly so a future default change can no longer silently rot them.

**Outcome:** Test-only repair of the 25 `skip_on_ci` live-Stan brms blocks that CI and the review gate never run (no Stan toolchain on CI). A live-Stan baseline enumerated 11 failing blocks: A-only `index` assertions broken by M44/ADR-054 (no-`type` `icc()` now returns all four formulations), plus O-Bayes-FML also broken on `level` by M38/ADR-048 (complete crossed fixed multilevel now returns subject+cluster). Fixed by pinning `type = "agreement"` on each shape-asserting brms fit (O-Bayes-FML also `level = "subject"`), and pinning the paired glmmTMB/lme4/brms-random reference fits in the three whole-vector-comparison blocks (O-Bayes-ML-agree/FCL/NML-agree) so each compares the agreement family end to end. Five stale comments corrected. Verified: live-Stan 67 blocks 0-fail; CI-parity `devtools::test()` 478 blocks 0-fail (23 skipped). No `R/` change.

**Decisions:** none.

**Review:** three-lens fan-out + scorer. Two findings, both scored ≥80, both fixed on-branch (comment-only): F1 (diff-bug, 90) a fifth stale "agreement by default" comment the sweep missed; F2 (blame-history, 85) an ADR-047 vs ADR-048 misattribution in the O-Bayes-FML comment. Prior-review lens: no finding.
