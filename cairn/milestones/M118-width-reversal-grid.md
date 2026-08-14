# M118: Measure Burch's leptokurtic width reversal on a both-components-non-normal grid

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6
- **Branch/PR:** `m118-width-reversal-grid`

## Goal

Measure, on a grid drawing both the subject effect and the residual from the
same non-Gaussian family, whether `"burch"` runs wider than `"searle"` as
Burch (2011) reports — assessment only, no shipped code.

## Scope

**In:** a pre-registered (GP5) disposition page; a sweep script whose generator
draws both components from the cell's family, located and scaled per burch2011
§3 (p. 1022); a committed per-cell table over Burch's own Fig. 2 geometry plus
the M111 geometry; a per-family kurtosis check against burch2011 Table 2
(p. 1021); a verdict `D-entry` applying the frozen rules; in-place correction of
the two `cairn/` records whose "neither committed grid tests this" claims this
milestone falsifies (`cairn/references/burch2011.md:157-160`,
`data-raw/m116-classical-width-comparison.R:24-27` and `:479-481`).

**Out:** the five asymmetric burch2011 Table 2 families — dropped at the plan
gate, not deferred; the verdict makes no skewed-family claim, though `chisq1`
stays in the M111-geometry block as a comparison point. Correcting the four
shipped user-facing surfaces that assert no measured grid varies the residual →
M119. Any change to `ci_method` behaviour, defaults or exported API → not
planned; a width finding is not a contract change.

## Acceptance criteria

- [ ] AC1 `cairn/references/classical-width-reversal-comparison.md` states the
      grid design and the frozen disposition rules W1–W3, of which W3
      pre-registers that a non-reproduction of the reversal is recorded as the
      finding and closes the question — no widened grid, no re-set threshold.
      Its commit is strictly earlier in `git log` than the commit adding the
      earliest of the milestone's derivation artifacts; its Results and
      Disposition sections are filled post-derivation and are outside the
      freeze.
- [ ] AC2 In every non-gaussian cell, `data-raw/m118-width-reversal-sweep.R`
      draws both the subject effect and the residual from the cell's family. A
      committed test walks the parsed body of its generator and fails when any
      component's draw resolves to a normal deviate, mutation-verified against a
      family of breaks that varies form as well as site: direct substitution, a
      draw hoisted into a variable above its use, and a namespace-qualified call.
- [ ] AC3 Each family's simulated excess kurtosis, at ≥ 100,000 draws, is within
      0.05 of burch2011 Table 2's printed value (p. 1021) for that family, for
      the subject-effect and residual draws alike.
- [ ] AC4 The grid is anchored on two independent references. Against
      burch2011 (p. 1027): at `k = 100`, `n = 5`, `rho = 0.25`, uniform for both
      components, the mean `"burch"` length over the mean `"searle"` length is
      within 0.01 of 0.88, `"burch"` coverage within 0.015 of 0.95, and
      `"searle"` coverage within 0.015 of 0.97. Against this repo: the gaussian
      cells of the M111 block reproduce their committed M111 counterparts'
      median width ratio within Monte-Carlo error, stated as a multiple of the
      binomial SE at `n_rep = 2000`.
- [ ] AC5 `data-raw/m118-width-reversal-by-cell.tsv`, mirrored to
      `tests/testthat/fixtures/width-reversal-by-cell.tsv`, is one flat block
      carrying one row per cell at `n_rep = 2000` — mean and median
      `"burch"`/`"searle"` length ratio, both coverages, replicate count — over
      the AC4 anchor cell, Burch's Fig. 2 block (`n = 5`, `k = 10(10)100`,
      `rho = 0.5`, the six symmetric Table 2 families), and the M111 block
      (`rho` ∈ {0.05, 0.10, 0.30, 0.60} × `(k,n)` ∈ {(10,5),(30,5),(50,5),(10,2)}
      × {gaussian, t5, uniform, chisq1}).
- [ ] AC6 A `cairn/DECISIONS.md` entry applies W1–W3 to that table and states,
      per symmetric family, whether the measured median `"burch"` width exceeds
      the measured median `"searle"` width, and whether `D-012 Amendment 1`'s
      reopening condition is thereby met.
- [ ] AC7 The `r-package` profile's `verify` slot is clean, and all four
      `data-raw/` checkers pass.

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T2, T4
- AC4 → T5, T6
- AC5 → T5, T6
- AC6 → T7
- AC7 → T8

## Tasks

- [x] T1 Author the frozen page from cairn's `templates/synthesis-note.md`:
      grid design, and W1–W3 as reversal-present / reversal-absent / mixed
      dispositions per the gate's record-and-stop answer. Commit alone, first.
- [x] T2 Write the generator in `data-raw/m118-width-reversal-sweep.R` — one
      standardized variate function per family applied to both components, sign
      and scale per burch2011 §3 (p. 1022); hand-roll power exponential(0,1,2.78)
      via the gamma route. No checkpoint cache (the M114 convention,
      `data-raw/m114-heldout-sweep.R:17-18`).
- [x] T3 Write the AST fence asserting both components are non-normal — the
      mirror of `assert_subject_only_dgp()`
      (`data-raw/m116-classical-width-comparison.R:65-126`) — plus its mutation
      harness over the three break forms in AC2. Leave m116's own two-script
      list untouched.
- [ ] T4 Write the kurtosis check against burch2011 Table 2.
- [ ] T5 Run the sweep over the three blocks via the shipped reducers
      `searle_endpoints()` / `burch_reml_endpoints()` (`R/ci-classical.R:109`,
      `:188`) off `classical_oneway_ss()`; write both tables.
- [ ] T6 Assert both AC4 anchors — the burch2011 printed cell and the M111
      gaussian cross-check; fill the page's Results section.
- [ ] T7 Fill Disposition; append the verdict `D-entry`; correct the two
      falsified `cairn/` records in place, marked and dated.
- [ ] T8 Run `verify`, the four `data-raw/` checkers, `air format .`, lintr.

## Work log

- 2026-08-13: created by /milestone-plan.
- 2026-08-13: plan-gate criteria audit ([O], fresh context) returned 2 blocking findings and 4 clear fixes, all applied; it also dropped a drafted "every figure is backed by the table" criterion, which contradicted the anchor criterion's mandate to record Burch's printed values and authored a records checker D-021/D-029 bar absent a package-defect trigger.
- 2026-08-13: plan gate chose symmetric-only families over adding Burch's five asymmetric families because the reversal claim is about symmetric leptokurtic data and no published figure would check a skewed finding; falsified by a user report or source claim of a width reversal on skewed data.
- 2026-08-13: plan gate chose record-and-stop over widening the grid on a non-reproduction, pre-registered as W3; falsified by a superseding frozen assessment.
- 2026-08-13: plan chose the shipped reducers over the M76/M111 prototypes (`data-raw/m76-classical-oneway-prototype.R`) because the measurement should describe what users get; falsified by the AC4 gaussian cross-check diverging from the M111 counterparts.
- 2026-08-13: plan chose no checkpoint cache over M111's cell-id cache because that cache is the known staleness trap already holding its own ROADMAP row and the closed-form legs make a resume unnecessary; falsified by a measured sweep runtime long enough to need resuming.
- 2026-08-13: plan tightened the anchor ratio tolerance to ±0.01 from a drafted ±0.02, which the audit measured at 5–10 SE and therefore near-vacuous at `n_rep = 2000`; GP5 forbids loosening it later.
- 2026-08-13: implement gate froze W1 as an ordered sign change across the six symmetric families — heavy-tailed limb wider, light-tailed limb narrower, each at ≥ 7 of 10 subject counts — over the weaker "wider in at least one heavy-tailed family" alternative, because the source predicts a kurtosis-ordered sign change rather than a blanket widening (p. 1024); falsified by a result where the limbs disagree in a way the partial tag cannot express.
- 2026-08-13: implement gate froze the consequence clause identically under all three tags — restate the measured facts, change no method recommendation — over reopening the runtime hint's advice on a reproduction; falsified by a user-facing need to advise on width under heavy tails, which stays out of M118 and M119 alike.
- 2026-08-13: T1 done — frozen page committed alone and first (GP5); its two settling directives were falsified on first run and fixed against the real text: `git grep -E` is POSIX ERE with no `\s`, and the burch2011 phrase wraps a line (the M115 line-based-search trap). Triage row generated programmatically from the enumerator's own key (M76 lesson).
- 2026-08-13: T2 done — `draw_standard()` supplies both components; power exponential hand-rolled via the gamma route, its beta = 2.78 confirmed against Burch's printed -0.5 (theoretical excess kurtosis -0.50049), which is what fixes his third parameter as the exponent rather than a scale.
- 2026-08-13: T3 done — AST fence plus a 7-mutation harness, all 7 red and the unmutated script accepted; the harness `sys.source()`s the test file with `test_that` stubbed, so guard and harness share one definition (M117 technique). Fence clause 1 (gen_oneway draws nothing itself) is what catches the hoisted and namespace-qualified forms a per-component check misses.
- 2026-08-13: T2/T3 hit the M62 lint lesson — four UPPERCASE constants passed `air` and would have reddened the CI lint job; renamed snake_case and the harness re-run after the rename (BSD `sed` has no `\b`, so the first rename silently did nothing and was caught by re-grepping rather than by trusting the command).
- 2026-08-13: post-audit consolidation merged the freeze pair into AC1 and the two anchors into AC4, clearing the >7-criteria tripwire; both merges concatenate audited text and were re-checked against the audit's three questions, with no claim added.

## Decisions

## Review
