# M87: MPL two-way random ICC(A,1) coverage pass — extended-range recalibration + GO/NO-GO verdict

**Status:** done (2026-07-23, PR #94 https://github.com/jmgirard/intraclass/pull/94)

**Goal:** GO/NO-GO on whether modified profile likelihood (MPL), with κ_m recalibrated
over ρ∈[0,0.9], gives a two-way random ICC(A,1) interval "not worse" than the incumbents
(MC default, parametric bootstrap) across the full ρ range incl. the near-zero boundary. Pre-registered; no exported method.

**Outcome:** **GO-for-opt-in** (D-014). Three seeded `data-raw/` scripts (no `R/`):
`m87-mpl-kappa-recalibration.R` recalibrated κ_m over ρ∈[0.05,0.9] per geometry
(0.676/0.501/0.826/0.340; fence-continuity to M86's 0.32/0.67 within ±0.01);
`m87-mpl-comparison-sweep.R` ran the paired 5-cell sweep (`m87-sweep-results.rds`);
`m87-mpl-verdict.R` applied the frozen criterion (`m87-verdict.rds`). MPL is the only
method ≥0.93 at all 5 cells; the two-way MC default aborts 25.9%/31.2% at the near-zero
boundary (the one-way M62/RR01 finding recurs); at the S↑ stress cell all three
alternatives under-cover, MPL alone survives. Cost: over-coverage + ~24% wider at
interior cells. Evidence: `references/mpl-twoway-random-comparison.md`.

**Decisions:** D-014 (GO-for-opt-in, extends D-006 to two-way; conditions on the
exported sibling: oracle-less sub-0.6 κ_m, per-geometry calibration cost,
balanced-complete + Gaussian). ROADMAP exported-`ci_method` candidate → GO.

**Review:** 3-lens fan-out + scorer — zero actionable findings (M86-F1 xiao-directive
extension verified load-bearing, F2 untouched). Scorer scored 2 doc notes 46/28
(both <80 → logged). No lessons retired.
