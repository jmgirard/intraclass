# M89: Numeric `unit` (ICC(A,m)) for `ci_method = "mpl"` — pole-safe Spearman-Brown projection

**Status:** done (2026-07-24, PR #96 https://github.com/jmgirard/intraclass/pull/96)

**Goal:** Enable a numeric `unit` (D-study projection ICC(A,m), any m≥1) under `ci_method = "mpl"` for balanced-complete two-way random absolute agreement, as the pole-safe Spearman-Brown image of the M88-validated ICC(A,1) MPL endpoints.

**Outcome:** `icc(..., ci_method = "mpl", unit = m)` now returns an ICC(A,m) interval for any m≥1 (integer or not) on the balanced-complete two-way random absolute-agreement cell — it aborted before. The interval is the exact SB image `npb_sb(rho,m) = m·rho/(1+(m−1)rho)` of the ICC(A,1) MPL endpoints, the same inheritance leg `mpl_ci()` already applied to ICC(A,k) at `est$divisor`; so the change was just removing the numeric-`unit` abort in the `icc()` mpl block (R/icc.R) plus a GP7 pole-safety comment. m=1→ICC(A,1), m=R→ICC(A,k). Pole-safe unconditionally (SB pole rho=−1/(m−1)<0 while MPL endpoints ∈[0,1]) — the opposite of the unbalanced one-way npbootstrap case, still deferred. Point is the engine glmmTMB REML ICC(A,m) (`icc_point`, already produced for montecarlo). All other fences unchanged (conf_level≠0.95, consistency, fixed raters, one-way/multilevel/replicate, unbalanced/incomplete abort). O-MPL inheritance leg + title extended to ICC(A,m); NEWS folded into the dev-cycle mpl entry.

**Decisions:** D-016 (pole-safe numeric-`unit` ICC(A,m) via SB inheritance, no new external oracle; lineage D-015 → M88).

**Review:** three-lens fresh-context review (diff-bug [O], blame-history [S], prior-review [S]) — no actionable findings, none scored ≥80. One sub-threshold [O] note fixed in review: a fixed-rater-refusal comment imprecision (R/icc.R:1462), zero behavioral change. All 6 AC verified fresh; consistency gate clean (cairn_validate exit 0, `devtools::check()` Status OK).
