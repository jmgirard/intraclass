# M82: Export classical boundary-robust one-way CIs as opt-in `ci_method` (SEARLE exact-F + Burch REML)

**Status:** done (2026-07-22, PR #89 https://github.com/jmgirard/intraclass/pull/89)

**Goal:** Export the two M76-validated classical one-way random-ICC intervals as opt-in `ci_method = "searle"` and `ci_method = "burch"`.

**Outcome:** Two deterministic closed-form CIs for the balanced one-way random ICC ship as opt-in `ci_method` values in new `R/ci-classical.R`: `"searle"` (exact-F pivot; `searle_endpoints`) and `"burch"` (REML kurtosis-adjusted `log(1+nθ̂)` limits; `burch_reml_endpoints` + the eq.13/15 kurtosis pipeline), ported from the M76 prototype. Both give a finite interval on the near-zero-ICC boundary where the MC default aborts, report the shared engine (REML) point, map ICC(k) via the shared `npb_sb()` Spearman-Brown image, and abort loudly off balanced one-way (guard shared with `npbootstrap`). Deterministic: `ci$samples`/`std.error` = `NA`, `print()` shows "closed form". O-Classical-OW flipped prototype-validated → suite-asserted (`test-ci-classical.R`, 36 assertions).

**Decisions:** D-013 (cross-cutting) — the classical `ci_method` API scope: `"searle"`/`"burch"` strings (D-010 doctrine), ICC(k) via the SB map (identity to the direct F-form), deterministic metadata. Fallback-on-abort default fenced out to a candidate.

**Review:** Three-lens fan-out + scorer. One finding: F1 (scored 80) — the AC4 cross-check was circular (reduced to divisor==n); fixed by building the SEARLE ICC(1,k) limits independently from the raw ANOVA F (mutation-proven) and scoping the Burch AC4 to the SB inheritance (no independent anchor). `devtools::check()` Status OK. Surfaced (out of scope) a pre-existing rotted `skip_on_ci` brms test → candidate row + chip.
