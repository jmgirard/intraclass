# M118: Measure Burch's leptokurtic width reversal on a both-components-non-normal grid

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6
- **Branch/PR:** `m118-width-reversal-grid` / https://github.com/jmgirard/intraclass/pull/127

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

- [x] AC1 `cairn/references/classical-width-reversal-comparison.md` states the
      grid design and the frozen disposition rules W1–W3, of which W3
      pre-registers that a non-reproduction of the reversal is recorded as the
      finding and closes the question — no widened grid, no re-set threshold.
      Its commit is strictly earlier in `git log` than the commit adding the
      earliest of the milestone's derivation artifacts; its Results and
      Disposition sections are filled post-derivation and are outside the
      freeze.
- [x] AC2 In every non-gaussian cell, `data-raw/m118-width-reversal-sweep.R`
      draws both the subject effect and the residual from the cell's family. A
      committed test walks the parsed body of its generator and fails when any
      component's draw resolves to a normal deviate, mutation-verified against a
      family of breaks that varies form as well as site: direct substitution, a
      draw hoisted into a variable above its use, and a namespace-qualified call.
- [x] AC3 Each of the seven families enumerated by `table2_kurtosis` in
      `data-raw/m118-width-reversal-sweep.R` — whose names a test requires to
      equal `draw_standard()`'s switch arms — is verified against burch2011
      Table 2 (p. 1021) by three legs. (a) The family's closed-form excess
      kurtosis, written out as a formula in its own parameters, equals the
      printed value within 0.01. (b) At ≥ 10^6 seeded draws the simulated mean
      is within 0.01 of 0 and the simulated variance within 0.01 of 1, for the
      subject-effect and residual draws alike. (c) At the same draws the
      simulated excess kurtoses are strictly increasing in printed kurtosis
      order, and are additionally within 0.02 of the printed value for uniform,
      power exponential and gaussian. No fixed tolerance is set for t(10),
      Laplace, t(5) or chi-squared(1): the sample excess kurtosis needs a finite
      eighth moment for a finite asymptotic variance, which t(5) — whose moments
      are finite only below order 5 — does not have, and the ordering leg covers
      those four. The power-exponential tolerance in (c) is load-bearing rather
      than incidental: `pe_beta` is the only distributional constant that legs
      (a) and (b) both inherit from the draw itself, so a wrong beta passes every
      other leg while leaving the family's kurtosis inside its neighbours'
      bracket.
- [x] AC4 The grid is anchored on two independent references. Against
      burch2011 (p. 1027): at `k = 100`, `n = 5`, `rho = 0.25`, uniform for both
      components, the mean `"burch"` length over the mean `"searle"` length is
      within 0.01 of 0.88, `"burch"` coverage within 0.015 of 0.95, and
      `"searle"` coverage within 0.015 of 0.97. Against this repo: each of the
      16 gaussian cells of the M111 block —
      `subset(build_cells(), block == "m111" & dist == "gaussian")` in
      `data-raw/m118-width-reversal-sweep.R` — reproduces the median
      per-replicate `"burch"`/`"searle"` width ratio of the matching
      `rho`/`k`/`n` cell in the committed
      `data-raw/m111-fallback-results.rds`. Each cell's discrepancy is stated
      as a multiple of the two-sample bootstrap standard error
      `sqrt(se_M118^2 + se_M111^2)`, each term the nonparametric bootstrap SE
      of that cell's median ratio over its own 2000 replicates, and no cell
      exceeds three of them.
- [x] AC5 `data-raw/m118-width-reversal-by-cell.tsv`, mirrored to
      `tests/testthat/fixtures/width-reversal-by-cell.tsv`, is one flat block
      carrying one row per cell at `n_rep = 2000` — mean and median
      `"burch"`/`"searle"` length ratio, both coverages, replicate count — over
      the AC4 anchor cell, Burch's Fig. 2 block (`n = 5`, `k = 10(10)100`,
      `rho = 0.5`, the six symmetric Table 2 families), and the M111 block
      (`rho` ∈ {0.05, 0.10, 0.30, 0.60} × `(k,n)` ∈ {(10,5),(30,5),(50,5),(10,2)}
      × {gaussian, t5, uniform, chisq1}).
- [x] AC6 A `cairn/DECISIONS.md` entry applies W1–W3 to that table and states,
      per symmetric family, whether the measured median `"burch"` width exceeds
      the measured median `"searle"` width, and whether `D-012 Amendment 1`'s
      reopening condition is thereby met.
- [x] AC7 The `r-package` profile's `verify` slot is clean, and all four
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
- [x] T4 Write the kurtosis check against burch2011 Table 2.
- [x] T5 Run the sweep over the three blocks via the shipped reducers
      `searle_endpoints()` / `burch_reml_endpoints()` (`R/ci-classical.R:109`,
      `:188`) off `classical_oneway_ss()`; write both tables.
- [x] T6 Assert both AC4 anchors — the burch2011 printed cell and the M111
      gaussian cross-check; fill the page's Results section.
- [x] T7 Fill Disposition; append the verdict `D-entry`; correct the two
      falsified `cairn/` records in place, marked and dated.
- [x] T8 Run `verify`, the four `data-raw/` checkers, `air format .`, lintr.

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
- 2026-08-13: AC3 amended at a mini gate (user-approved) — the original "within 0.05 of the printed value" is unsatisfiable for t(10)/t(5)/chi-squared(1), a mis-set pin GP5 permits correcting prospectively rather than a bar loosened post hoc: no test asserted it yet, and no replicate count reaches it because the sample excess kurtosis has no finite asymptotic variance at t(5). The per-family spreads that decide which three families carry a tolerance are the ones `Rscript data-raw/m118-kurtosis-spread.R` prints; that script also asserts the pinned/unpinned split against them, so the split reds there rather than silently rotting if a family's behaviour changes.
- 2026-08-13: the amended AC3 wording went to a fresh-context [O] reader before being written, which found the drafted version blind to a wrong `pe_beta` — it passes the closed-form leg (same constant), the variance leg (powexp alone derives its divisor from that constant) and the ordering leg (beta in 2.2-3.4 leaves the kurtosis inside its neighbours' bracket). The shipped wording adds the per-family tolerance that closes it; the drafted claim "the ordering leg is what catches a wrong constant" was false and is not in the shipped text.
- 2026-08-13: T4 done — 41 assertions, no skips and no `NOT_CRAN` needed (the whole file runs in ~2s, so `skip_on_cran()` was dropped rather than left to hide a leg). `data-raw/m118-kurtosis-spread.R` measures the AC's load-bearing claim rather than asserting it: every wrong beta tried (2.2, 2.5, 3.0, 3.4) keeps the variance at ~1.002 and the kurtosis inside the uniform/gaussian bracket, so both other legs miss it and only the 0.02 tolerance catches it.
- 2026-08-13: T5 done — 125 cells x 2000 reps in 0.3 min at 4 workers, 0 degenerate cells; both closed-form legs, so the sweep is ~100x cheaper than M111's MC-bearing one.
- 2026-08-13: W1 is met on every limb at 10 of 10 subject counts — no marginal call. The sign change sits exactly where the frozen page flagged it as demanding: gaussian stays below 1 (0.973 at k=10 to 0.996 at k=100) and t(10) is above it at every k (1.004 to 1.080), so the crossing falls between excess kurtosis 0.0 and 1.0 as W1's t(10) limb required.
- 2026-08-13: AC4's repo leg amended at a mini gate (user-approved), fresh [O] reader first. Three defects, each fatal to verifiability: it named a binomial SE for a comparison of medians (a statistic in the wrong units); a one-sample SE would have made a nominal 3-sigma bound an effective 2.12 sigma, giving a ~42% false-failure rate over 16 cells on a precondition whose documented meaning is that the grid is defective; and "median width ratio" was ambiguous between the ratio of medians and the median of ratios, which differ by more than the discrepancy being bounded. It now names the median of ratios — the statistic W1 itself reads — and the `.rds`, the only committed artifact carrying the per-replicate widths both sides need.
- 2026-08-13: the 3-sigma bound was chosen with the discrepancies already in hand, so it is logged rather than presented as blind: it is the off-the-shelf convention, not the tightest value that passes (measured worst case 1.68), and a tighter post-hoc value was declined at the gate for that reason. The frozen W1-W3 rules, their aggregation and their consequence clause are untouched — AC4 is a validation precondition, not one of them.
- 2026-08-13: an intermediate comparison compared M113's ratio-of-medians against M118's median-of-ratios and was discarded before any figure from it was recorded — the M116 lesson about pooling statistics that are not the same statistic, hit one level down.
- 2026-08-13: T6 done — both anchors assert from committed `data-raw/m118-anchor-checks.R`; Results filled. Every figure written into the page was then re-derived from the committed fixture, which caught two wrong coverage ranges: the pooled leptokurtic ranges had been composed by reading two of the three family rows, dropping t(10)'s 0.947 and 0.940, and the true pooled ranges overlap so the contrast as drafted was false. Restated per family (the M115/M116 subset-derived-claim lesson, recurring).
- 2026-08-13: T7 done — Disposition filled, D-030 appended, and the falsified records corrected in place. A sweep for the claim class found a THIRD stale site the scope's hand-list of two had missed — `cairn/references/INDEX.md:187`, a line this milestone itself wrote at T1 — which is the M118 lesson in miniature: a hand-list goes stale between the writing and the checking, and only the sweep caught it.
- 2026-08-13: D-030 records the reopening condition as met WITHOUT superseding D-012 Amendment 1: that amendment's corrected wording is scoped to the M76 grid and stays true of it, so what this grid falsifies is the bound the shipped docs put on the finding, not the amendment.
- 2026-08-13: the m116 comparison script's header lines were edited, so its TSV was regenerated to keep generator and artifact in step; the data rows are byte-identical and the committed test fixture is unchanged.
- 2026-08-13: T8 done — full `devtools::test()` clean at 7158 passing, 0 failures; the 3 warnings are the deliberate fixed-rater conditions the brms tests exercise and the 2 skips are the pre-existing vignette-not-installed legs, neither touched by a branch that changes no R/ code. air, lintr, all four data-raw checkers, the three M118 harnesses and cairn_validate all green.
- 2026-08-13: status → review.
- 2026-08-13: post-audit consolidation merged the freeze pair into AC1 and the two anchors into AC4, clearing the >7-criteria tripwire; both merges concatenate audited text and were re-checked against the audit's three questions, with no claim added.

## Decisions

## Review

Evidence gathered 2026-08-13 on `m118-width-reversal-grid` at PR #127; every
line below is a command run at review, never recall.

- **AC1 — met.** The rules page was added in `f88cc22`; all three derivation
  artifacts (`.rds` and both TSVs) first appear in `d4b1878`.
  `git merge-base --is-ancestor` confirms the page commit is strictly earlier,
  so commit order corroborates the freeze (GP5). The page carries the frozen
  grid design and the W1–W3 table, W3 carrying the record-and-stop clause
  verbatim ("no widened grid, no additional families, no re-set threshold"),
  and its Results and Disposition sections are the two the criterion places
  outside the freeze.
- **AC2 — met.** `test-m118-both-components-dgp.R` passes 2/2.
  `data-raw/m118-dgp-fence-mutations.R` accepts the unmutated script and
  rejects all 7 planted defects, which vary form as well as site: direct
  substitution, a draw hoisted into a variable above its use, and a
  namespace-qualified call, on each component, plus a dispatcher that stops
  branching on `dist`. The criterion names three break forms; the harness runs
  seven, covering all three.
- **AC3 — met.** `test-m118-family-kurtosis.R` passes 41/41 with 0 skips and
  needs no `NOT_CRAN`. All three legs run: closed forms written in each
  family's own parameters against Table 2, mean and variance at 10^6 and
  2×10^6 seeded draws, and the ordering leg plus the 0.02 tolerance on
  uniform / power exponential / gaussian. A fourth test pins the family
  enumeration to `draw_standard()`'s own switch arms, so an eighth family
  cannot escape the checks.
- **AC4 — met, both legs.** `data-raw/m118-anchor-checks.R` asserts them and
  exits clean. Against burch2011 (p. 1027): mean length ratio 0.8807 against
  the printed 0.88 (gap 0.0007, tolerance 0.01); `"burch"` coverage 0.9600
  against 0.95 (gap 0.0100, tolerance 0.015); `"searle"` coverage 0.9790
  against 0.97 (gap 0.0090, tolerance 0.015). Against this repo: the worst of
  the 16 gaussian cells is 1.68 two-sample bootstrap SEs against the bound of
  3. Recorded and not asserted, per the script's own note: 13 of the 16
  differences are negative, mean z = −0.30.
- **AC5 — met.** Both files carry 125 rows × 14 columns as one flat block and
  are identical to each other. Blocks are anchor 1 / fig2 60 / m111 64. Every
  row has `n_rep = 2000` and `n_skip = 0`. The fig2 block is `k` = 10(10)100,
  `rho` = 0.5, `n` = 5 over the six symmetric families; the m111 block is
  `rho` ∈ {0.05, 0.1, 0.3, 0.6} × (k,n) ∈ {10-5, 30-5, 50-5, 10-2} ×
  {chisq1, gaussian, t5, uniform}; the anchor is k=100, n=5, rho=0.25,
  uniform. The required columns are all present: `mean_ratio`,
  `median_ratio`, both median widths, both coverages, and the replicate
  count.
- **AC6 — met.** D-030 names the tag (`W1, reproduced`), gives the ratio at
  k = 10 and k = 100 for each of the six symmetric families under the two
  limbs, and states `D-012 Amendment 1`'s reopening condition as met. It also
  says explicitly what it does not disturb: Amendment 1's own wording is
  scoped to the M76 grid and stays true of it, so nothing is superseded.
- **AC7 — met.** `devtools::test()`: 7158 passing, 0 failures. The 3 warnings
  are the deliberate fixed-rater conditions the brms tests exercise and the 2
  skips are the pre-existing vignettes-not-installed legs; neither is touched
  by a branch that changes no `R/` code. All four `data-raw/` checkers pass.

**Consistency gate.** `cairn_validate`: 16 PASS, 8 advisory OK, none failing —
including `coverage complete` and `weight caps`. No `DESIGN.md` principle
changed, so `cairn_impact` does not apply. Toolchain slot: `devtools::document()`
leaves no diff; `man/`, `NAMESPACE` and `data/` are untouched by the branch;
README is untouched and in sync; `pkgdown::check_pkgdown()` reports no problems;
no new top-level files, so no `.Rbuildignore` entry is owed. No NEWS entry is
owed and none was written — the branch changes no `R/`, `src/` or `inst/` file,
so nothing user-visible ships here; M119 carries that.
