# M87: MPL two-way random ICC(A,1) coverage pass — extended-range recalibration + GO/NO-GO verdict

- **Status:** review
- **Priority:** normal
- **Depends on:** M86
- **Driving RR:** —
- **Principles touched:** IP1, GP5, GP6
- **Branch:** m87-mpl-coverage-verdict-twoway-random

## Goal

Decide GO/NO-GO on whether MPL — with κ_m recalibrated over ρ∈[0,0.9] — gives a
two-way random ICC(A,1) interval "not worse" than the package's incumbents (MC
default, parametric bootstrap) across the full ρ range including the near-zero
boundary, via a pre-registered coverage-band + width pass. No exported method.

## Scope

**In:**
- Recalibrating κ_m over an extended grid ρ∈[0,0.9] using M86's validated
  calibration machinery (the published κ_m are maxima over ρ≥0.6 and are **not**
  transferable to the boundary — `xiao2013.md`, "the ρ_L = 0.6 fence").
- A pre-registration file committed **before any results** (GP5): design, cells
  (incl. a near-zero-ρ boundary cell and a few-subjects corner, GP6), the two
  incumbents, the "not worse" coverage-band + width criterion, and the prior.
- A paired comparison coverage sweep: MPL (recalibrated κ_m) and naive PL
  (reference) vs the MC default and parametric bootstrap, on the same seeded
  datasets, across ρ∈[0,0.9]; MC `n_ok` / boundary-abort behavior recorded.
- Verdict + `cairn/DECISIONS.md` D-entry (GO/NO-GO, framing, conditions on any
  exported sibling); candidate-row updates.

**Out:**
- Exported `ci_method = "mpl"` → GO-gated candidate, not this milestone.
- Unbalanced/incomplete two-way designs → out (xiao2013 balanced-complete only).
- GV as live code → frozen xiao2013 Table 6 values for context only.
- Non-normality robustness → out (Gaussian DGP, matching xiao2013).

## Acceptance criteria

- [ ] AC1 — A pre-registration file is committed under `cairn/references/`
      **before** any comparison result (git ordering verifiable), freezing the
      design, cells, incumbents, "not worse" criterion, and prior (GP5).
- [ ] AC2 — κ_m is recalibrated over ρ∈[0,0.9] with M86's calibration function;
      the extended grid's value at ρ=0.6 matches M86's validated published-region
      κ_m within ±0.10 (the one available anchor — no external oracle exists below
      0.6, so continuity at the fence is the check).
- [ ] AC3 — The paired sweep runs MPL, naive PL, MC default, and parametric
      bootstrap on the same seeded datasets across the pre-registered cells,
      including ≥1 near-zero-ρ boundary cell and ≥1 few-subjects corner (GP6), with
      MC `n_ok` recorded per cell (M62 lesson: coverage conditional on non-abort).
- [ ] AC4 — The two-way MC default's boundary behavior (σ²_s→0 abort rate and
      conditional coverage) is recorded, stating whether the one-way M62/RR01
      boundary finding (28–39% classed aborts) recurs in the two-way random design.
- [ ] AC5 — The "not worse" criterion is applied cell-by-cell and a GO/NO-GO
      verdict is stated with the deciding cells named; recorded as a D-entry with
      the framing and any conditions on an exported sibling.
- [ ] AC6 — The evidence note is updated with results + verdict; candidate rows
      updated (the exported-`ci_method` sibling GO-gated on this outcome); the
      generalizing-claims enumerator (`--check`) is green with any new triage rows.
- [ ] AC7 — `lintr::lint_package()` and `air format --check` clean on new
      `data-raw/` scripts.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T5

## Tasks

- [x] T1 — Write and commit the pre-registration (design; cells incl. a near-zero-ρ
      boundary + few-subjects corner; incumbents = MC default + parametric
      bootstrap; coverage-band + width "not worse" criterion; stated prior) BEFORE
      any comparison run (GP5).
- [x] T2 — Recalibrate κ_m over ρ∈[0,0.9] via M86's calibration function; verify
      continuity at the ρ=0.6 fence against M86's validated value.
- [x] T3 — Build the paired comparison harness (M62-style,
      `data-raw/npbootstrap-oneway-comparison` as the shape): MPL / naive PL / MC /
      parametric bootstrap on identical seeded datasets across the cells; record MC
      `n_ok` and boundary-abort behavior.
- [x] T4 — Apply the criterion, tabulate coverage/width per cell, name the deciding
      cells, and write the verdict.
- [x] T5 — Append results + verdict to the evidence note; write the D-entry; update
      candidate rows; run the enumerator, `lintr`, and `air format --check`.

## Work log

- 2026-07-23: created by /milestone-plan (split from the PL-CI candidate; depends on M86's validated machinery).
- 2026-07-23: gate — 95% nominal, 5-cell grid (C1–C5), n_rep=1000 cheap / 500 pboot (B=199) background (all recommended options).
- 2026-07-23: T1 — froze the M87 pre-registration in `references/mpl-twoway-random-comparison.md` (design, cells, κ_m recalibration + fence continuity anchor, "not worse" criterion, prior) BEFORE any comparison run (GP5); +2 OUT-repo-analysis triage rows for the C3/C4 cell-role labels (enumerator --check green).
- 2026-07-23: T2 — `m87-mpl-kappa-recalibration.R` recalibrated κ_m over ρ∈[0.05,0.9]×δ at α=0.05 for the 4 geometries: (3,20)=0.676, (3,10)=0.501, (3,50)=0.826, (5,20)=0.340 (argmax at δ=16, ρ=0.05–0.20 — verified, not assumed; ~40–80% above the ρ≥0.6 scan max). AC2 fence continuity PASS: (3,10) 0.326 vs M86 0.32, (3,50) 0.665 vs 0.67 (both |diff|<0.01). Fixture `m87-kappa-recalibration.rds`.
- 2026-07-23: T3 — `m87-mpl-comparison-sweep.R` paired sweep (n_rep=1000 cheap / 500 pboot B=199, ~3.85 h) across C1–C5 → `m87-sweep-results.rds`. AC4: two-way MC default aborts (`intraclass_singular_fit`) 25.9% (C2) / 31.2% (C3) of near-zero datasets — the one-way M62/RR01 28–39% finding recurs. naive PL under-covers 0.880 at C4 (xiao's S↑ finding reproduces).
- 2026-07-23: T4 — `m87-mpl-verdict.R` applied the frozen criterion → **GO**: MPL not worse at every cell; the only method ≥0.93 at all 5 (MC fails C4=0.904; pboot fails C1=0.926, C4=0.800; naive PL fails C4=0.880). Deciding cells: C2/C3 boundary (MPL 0.995/0.994, 0 aborts vs MC 25.9%/31.2%) + C4 stress (MPL 0.963 sole survivor). Cost: over-coverage 0.96–0.995, ~24% wider than MC at interior cells. Fixture `m87-verdict.rds`.
- 2026-07-23: T5 — appended Results + Verdict to `references/mpl-twoway-random-comparison.md`; wrote **D-014** (GO-for-opt-in, extends D-006 to two-way; conditions on the exported sibling); flipped the ROADMAP exported-`ci_method` candidate GO-gated → GO-for-opt-in. Extended the D-009 settling directives in `xiao2013.md` + `xiao2009.md` to exclude the 3 M87 scripts (M86-F1 class); +7 OUT-repo-analysis triage rows. Checkers green: enumerator `--check`, check-references, `lintr`, `air format --check`.
- 2026-07-23: completion — `devtools::test()` clean (FAIL 0 | PASS 4303; no `R/`/tests surface changed), `cairn_validate` all checks pass (no new advisories), caps clean (milestone 89/150, ROADMAP 37/60). Status → review.

## Decisions

## Review
