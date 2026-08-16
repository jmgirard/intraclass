# M121: Measure the `npbootstrap` interval's coverage on the frozen skew grid

**Status:** done (2026-08-16, PR #130 https://github.com/jmgirard/intraclass/pull/130)

**Goal:** Measure `ci_method = "npbootstrap"` per-cell coverage on the 64-cell
one-way skew grid the M111 fixture holds, against a pre-registered floor.

**Outcome:** `data-raw/m121-npbootstrap-skew-sweep.R` regenerates every M111
replicate from its recorded seeds (platform gate; endpoint identity check at
1e-12, row and endpoint counts asserted separately), gates on the ukoumunne2003
Table I anchors before any grid cell, and adds an npbootstrap leg whose aborts
are read from the condition class. `data-raw/m121-npbootstrap-skew-coverage.tsv`
holds 64 cells × 4 legs in M113's column set; rule N1 is frozen in
`cairn/references/npbootstrap-skew-response-comparison.md`. Measured: 26/64
below the 0.93 floor, worst 0.8730, zero aborts over 128,000 replicates,
regeneration exact at all 512,000 endpoints.

**Decisions:** D-031 (the N1 verdict). Milestone-local: a declared checkpoint
site may hold no bare `readRDS`, so non-checkpoint inputs read through a new
`ckpt_read_input()` that leaves the runtime trace intact.

**Review:** Three lenses, 17 findings scored; one actioned — F10 (85), a lost
`mclapply` worker passing the `try-error` completeness test at both sites,
regressing the M112 lesson; fixed with a probe. F1 (62) fixed at the
maintainer's direction. F6/F7 became a ROADMAP candidate row.
