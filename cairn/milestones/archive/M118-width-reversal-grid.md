# M118: Measure Burch's leptokurtic width reversal on a both-components-non-normal grid

**Status:** done (2026-08-14, PR #127 https://github.com/jmgirard/intraclass/pull/127)

**Goal:** Measure, on a grid drawing both the subject effect and the residual from the same non-Gaussian family, whether `"burch"` runs wider than `"searle"` as Burch (2011) reports — assessment only, no shipped code.

**Outcome:** The reversal reproduces. `data-raw/m118-width-reversal-sweep.R` draws both `A_i` and `e_ij` from the cell's family via `draw_standard()`, located and scaled per burch2011 §3; 125 cells × 2000 reps land in `m118-width-reversal-by-cell.tsv` (mirrored to a test fixture). Median `"burch"`/`"searle"` ratio at k=10/100: t(10) 1.004/1.080, Laplace 1.096/1.300, t(5) 1.065/1.296 above 1; uniform 0.917/0.898, powexp 0.947/0.951, gaussian 0.973/0.996 below — both limbs at 10 of 10 subject counts, so the sign change sits between excess kurtosis 0.0 and 1.0. Anchored on burch2011 p. 1027 (ratio 0.8807 vs 0.88) and on the M111 gaussian cells (worst 1.68 two-sample bootstrap SE). Nothing user-facing shipped; M119 carries the doc reconciliation.

**Decisions:** D-030 (verdict; `D-012 Amendment 1`'s reopening condition met, its wording untouched). Milestone-local: D-030 was corrected in place rather than by an appended amendment, on the ground that it had not yet merged; and the terminal-row rotation was recorded as owed at this `done` flip.

**Review:** Five passes. Three-lens fan-out + scorer: 39 findings, 4 actioned (A1 86, C6 85, B1 82, C10 80), 35 below the bar. A1 drove two gated AC2 amendments — the criterion now rests on two committed measurements, not on source inspection, after `dist <- "gaussian"`, a `rho`-gated local shadow, `dist[1] <- ...` and `assign("dist", ...)` each defeated a fence in turn. C6's rotation landed in this hygiene commit. Final: 7161 passing, cairn_validate clean, CI green on all seven checks.
