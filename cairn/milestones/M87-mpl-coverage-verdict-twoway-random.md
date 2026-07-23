# M87: MPL two-way random ICC(A,1) coverage pass — extended-range recalibration + GO/NO-GO verdict

- **Status:** in-progress
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

- [ ] T1 — Write and commit the pre-registration (design; cells incl. a near-zero-ρ
      boundary + few-subjects corner; incumbents = MC default + parametric
      bootstrap; coverage-band + width "not worse" criterion; stated prior) BEFORE
      any comparison run (GP5).
- [ ] T2 — Recalibrate κ_m over ρ∈[0,0.9] via M86's calibration function; verify
      continuity at the ρ=0.6 fence against M86's validated value.
- [ ] T3 — Build the paired comparison harness (M62-style,
      `data-raw/npbootstrap-oneway-comparison` as the shape): MPL / naive PL / MC /
      parametric bootstrap on identical seeded datasets across the cells; record MC
      `n_ok` and boundary-abort behavior.
- [ ] T4 — Apply the criterion, tabulate coverage/width per cell, name the deciding
      cells, and write the verdict.
- [ ] T5 — Append results + verdict to the evidence note; write the D-entry; update
      candidate rows; run the enumerator, `lintr`, and `air format --check`.

## Work log

- 2026-07-23: created by /milestone-plan (split from the PL-CI candidate; depends on M86's validated machinery).

## Decisions

## Review
