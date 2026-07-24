# M90: MPL κ_m recalibration + coverage GO/NO-GO at conf_level ∈ {0.90, 0.99}

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP5, GP6
- **Branch/PR:** m90-mpl-conf-level-calibration

## Goal

GO/NO-GO on whether the two-way random ICC(A,1) MPL interval, with κ_m
recalibrated at α∈{0.10, 0.01}, covers at nominal across the ρ range (incl. the
near-zero boundary) at conf_level 0.90 and 0.99 — the prerequisite for M91.

## Scope

**In:** Recalibrate the MPL correction constant κ_m at two new confidence levels
so a later milestone can export them. Parametrize the M87/M88 calibration by α;
generate seeded κ_m tables at α∈{0.10, 0.01} (two-sided) over the shipped (R,S)
grid (R 2:10 × S {10,15,20,30,50,100}), using M88's scan→top-k bias-corrected
method with larger n_mc at α=0.01 for its deeper tail (M86 tail-noise lesson).
Freeze a pre-registered per-level coverage criterion (GP5) in a references note
before any run, run the paired coverage sweep across the M87 decisive cells, and
render a per-level GO/NO-GO verdict. κ_m fixtures land in `data-raw/` (`.rds`);
they are NOT yet wired into `R/sysdata.rda`.

**Out:** No exported code, no fence lift, no `R/` change → M91 (consumes this
milestone's fixtures + GO). Levels other than {0.90, 0.99} → candidate row.
Arbitrary continuous conf_level via α-interpolation → out (off-level aborts,
decided in M91). Design/geometry fences (fixed, consistency, unbalanced,
off-grid) → unchanged, separate candidates.

## Acceptance criteria

- [ ] AC1: Seeded κ_m tables at α=0.10 (conf_level 0.90) and α=0.01 (conf_level
      0.99) exist over the full shipped (R,S) grid, provenance in `meta`. For
      **0.90**, the recalibrated κ_m over ρ∈[0.6,0.9] reproduces xiao2013's
      published two-sided κ_m (Table 3 δ_U=16 / Table 6: 0.32, 0.52, 0.67, 0.13,
      0.23, 0.33) within the M86/M87 tolerance — a direct external oracle (IP1).
      For **0.99** (no external oracle) and both levels' sub-0.6 tail, the
      scan-vs-top-k internal cross-check (M88's guard) agrees within MC
      tolerance. Recorded in the note.
- [ ] AC2: At each level, the MPL interval built at the recalibrated κ_m meets
      the pre-registered coverage criterion (frozen + dated in the references
      note BEFORE any run, GP5) at every M87 decisive cell — the calibration
      constant validated by its defining coverage property (M86 lesson), across
      the near-zero boundary (GP6). Evidence: seeded sweep fixture + verdict.
- [ ] AC3: A per-level GO/NO-GO verdict applying the frozen criterion to the
      sweep, with verdict + evidence recorded in the references comparison note;
      a NO-GO level is named and routed to a candidate row, not exported.
- [ ] AC4: The note states the **level-specific** oracle posture — conf_level
      0.90's κ_m is externally oracle-backed over ρ∈[0.6,0.9] (xiao2013 Table
      3/6, IP1); its sub-0.6 tail and all of conf_level 0.99 have no external
      oracle (D-014(i) inherited), established by simulated coverage only.

## Coverage

- AC1 → T2, T4
- AC2 → T1, T3
- AC3 → T1, T4
- AC4 → T1, T4

## Tasks

- [ ] T1: Author the pre-registered per-level (0.90, 0.99) coverage criterion +
      no-oracle disclosure in a references note (extend
      `references/mpl-twoway-random-comparison.md` or a sibling), frozen + dated
      before any calibration/sweep run (GP5). (RB tripwire: no-oracle — sub-0.6
      κ_m at new levels; posture inherited from D-014(i).)
- [ ] T2: Parametrize the κ_m calibration (`data-raw/m87-mpl-kappa-recalibration.R`,
      `data-raw/m88-mpl-kappa-table.R`) by α; run a seeded background job
      generating κ_m at α=0.10 and α=0.01 over the shipped grid (larger n_mc at
      α=0.01; top-k bias-correction). Background (~2–2.5 h each). → `data-raw/*.rds`.
- [ ] T3: Coverage sweep at each level across the M87 decisive cells (interior,
      near-zero boundary, few-subjects corner, xiao worst case, breadth),
      seeded, paired (mirror `data-raw/m87-mpl-comparison-sweep.R`). Background
      (~4–6 h each). → sweep fixture.
- [ ] T4: Apply the frozen criterion → per-level verdict script + fixture; record
      verdict + evidence in the references note. GO authorizes M91; a NO-GO level
      → candidate row (the D-entry lands at review, mirroring D-014).

## Work log

- 2026-07-24: created by /milestone-plan (with M91); conf_level {0.90,0.99} for MPL, level set chosen at the plan gate; lineage D-015 → this.
- 2026-07-24: /milestone-implement start; status → in-progress; branch m90-mpl-conf-level-calibration cut from main.
- 2026-07-24: amended AC1/AC4 (gate) — conf_level 0.90's κ_m over ρ≥0.6 has a direct external oracle (xiao2013 Table 3/6 at α=0.10, IP1; M86 already reproduced 0.32/0.67/0.33); no-oracle posture now level-specific (0.90 sub-0.6 tail + all 0.99 only). Principles touched += IP1; AC1 coverage += T4.
- 2026-07-24: escalating to Fable via /milestone-brief (RB tripwire: no-oracle) before freezing the T1 criterion or running any sweep — the α=0.01 (0.99) deep-tail κ_m + sub-0.6 extrapolation have no external oracle; question per the gate. T1–T4 paused pending the RR.

## Decisions

## Review
