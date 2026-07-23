# M84: Unbalanced one-way transformed bootstrap-t — ICC(1)

**Status:** done (2026-07-23, PR #91 https://github.com/jmgirard/intraclass/pull/91)

**Goal:** Extend `ci_method = "npbootstrap"` to the single-rating ICC(1) on unbalanced one-way random designs — the unequal-`n_i` IJ SE and the `n₀` transform — validated against the balanced limit and ohyama2025.

**Outcome:** `ci_method = "npbootstrap"` now serves the **unbalanced** one-way ICC(1) (`unit = "single"`). `npb_anova()` is generalized to per-subject `n_i`: the ANOVA effective size `n0 = (N − Σn_i²/N)/(k−1)` (ohyama2025 eq. 3) in the `log F` transform, the per-`n_i` eq. 7 IJ SE, and studentization of the C-dropped pivot `theta = log SSA − log SSE` (Form A) — one reducer path, balanced (`n0=n`, `C` invariant) the exact special case. Dispatch (`R/icc.R`) serves unbalanced `unit="single"`, aborts unbalanced `"average"`/numeric (→M85), keeps `"searle"`/`"burch"` balanced-only. Ships the unbalanced leg in `ORACLES.md` O-NPBoot (reduces-to-balanced ≤1e-10 + ohyama §4 Example 2 `ρ̂=0.585` + a 2000-rep Fig. 2 plot-read coverage sweep, three cells within ±0.02), plus `@param`/@details/NEWS.

**Decisions:** MD-1 (milestone-local) — ANOVA `n₀` (eq. 3, not the harmonic mean) + the C-dropped Form-A pivot the IJ SE is derived for; the `(RB tripwire: no-oracle)` resolved by investigation (ohyama's published unbalanced method + ukoumunne Appendix A), not escalated to Fable.

**Review:** Consistency gate clean (`cairn_validate` 0; `devtools::check()` 0/0/0; lintr 0; generalizing-claims in sync). Three fresh-context lenses (diff-bug [O], blame-history [S], prior-review [S]) — 0 actioned findings; scorer a no-op. One review-side evidence gap closed: a direct-reducer AC6 test for the SSE=0 / tiny-k modes `icc()` masks behind the engine point-fit.
