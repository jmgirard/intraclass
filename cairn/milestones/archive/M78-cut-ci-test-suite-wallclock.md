# M78: Cut CI test-suite wall-clock — parallelism + residual boot_samples (GO/NO-GO)

**Status:** done (2026-07-21, PR #84 https://github.com/jmgirard/intraclass/pull/84)

**Goal:** Cut CI wall-clock by shrinking the testthat suite — the measured cost — not the already-cached dependency install, without weakening any oracle.

**Outcome:** Added a `Scale testthat parallel workers` step to `.github/workflows/check-standard.yaml` setting `TESTTHAT_CPUS=$(getconf _NPROCESSORS_ONLN)` (nproc/2 fallbacks) — testthat's `default_num_cpus()` caps workers at 2 otherwise. Measured GO (modest): Windows `testthat.R` 18m→15m (~17%; check job 21m20s→18m3s), the PR-matrix long pole → overall CI wall-clock ↓~3m; ubuntu flat (13m; runner ~2.5-core, saturated at 2 workers). Lever B (residual structural `boot_samples`) near-exhausted — M59 had floored the named files; only `test-boundary-policy.R:83` and `test-icc-lavaan.R:521` cut 199→99. No O1/O2 coverage/agreement count changed (GP5/GP6). Also corrected the M77 CI-cost misattribution.

**Decisions:** D-011 (CI wall-clock is the testthat suite, not the cached dep install; retires the dep-caching candidate).

**Review:** 3 lenses + scorer, zero actioned findings. One finding (F1 — parallelism step also affects push-only macos-latest, unverified pre-merge) scored 35, excluded as an inherent slim-PR-matrix tradeoff. Blame-history + prior-review clean. All 8 checks green. Hygiene: added an M78 LESSONS line (testthat worker cap + runner-core reality); pruned the stalest M54 line (new-engine-contract lesson, obsolete under GP4's closed engine roster) to hold the 50-line cap.
