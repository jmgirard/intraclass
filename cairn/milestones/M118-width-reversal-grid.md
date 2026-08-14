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
- [ ] AC2 `data-raw/m118-width-reversal-sweep.R` draws both the subject effect
      and the residual from the cell's family. Two committed procedures bound
      that claim, both of them procedures over `gen_oneway` alone, and this
      criterion promises only what they decide.
      (a) A walk of `gen_oneway`'s parsed body asserts three things: that each
      of the two component assignments `a` and `e` calls `draw_standard()`
      exactly once, passing the symbol `dist`; that no call in the body
      resolves to a name matching `^r[a-z]+$` other than `rep`, `return`,
      `round` and `rev`; and that no formal parameter of `gen_oneway` is the
      target of a `<-`, `=` or `<<-` at any nesting depth.
      (b) A composition leg evaluates `gen_oneway` out of the script and asserts
      the recovered ICC is within 0.05 of `rho` at `rho = 0.05`, and within 0.10
      at `rho = 0.25` and `rho = 0.50`, for all seven families at `k = 400`,
      `n = 5`, seed 900001. Both legs are mutation-verified by
      `data-raw/m118-dgp-fence-mutations.R`, which requires the unmutated script
      to be accepted and every mutation the file commits to be rejected — among
      them, for (b), a scale error, a subject/residual scale swap and a
      mis-composition. The tolerances sit between a measured legitimate spread
      and the nearest mutation at every `rho`; both are what
      `data-raw/m118-composition-spread.R` prints.
      Outside these two procedures the criterion promises nothing, and neither
      decides what an arbitrary program resolves to. Whatever fixes a cell's
      family or design anywhere but in `gen_oneway`'s own body, or at run time
      rather than in the parsed text, is unpromised: `assign()`, a shadowed
      `draw_standard`, a `for`-loop binding a parameter, post-parse body surgery
      and the `run_cell` call site are instances found at review, not the
      boundary. What bounds the grid this milestone actually ships is AC4's
      burch2011 anchor, whose uniform cell is the one measured point at which a
      wrong family shows.
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
- AC2 → T2, T3, T9
- AC3 → T2, T4
- AC4 → T5, T6
- AC5 → T5, T6
- AC6 → T7
- AC7 → T8

## Tasks

- [x] T1 Author the frozen page (grid design, W1–W3); commit alone, first.
- [x] T2 Write the generator: one standardized variate per family applied to
      both components, per burch2011 §3 (p. 1022); no checkpoint cache.
- [x] T3 Write the AST fence — the mirror of `assert_subject_only_dgp()`
      (`data-raw/m116-classical-width-comparison.R:65-126`) — plus its mutation
      harness. Leave m116's own two-script list untouched.
- [x] T4 Write the kurtosis check against burch2011 Table 2.
- [x] T5 Run the sweep via the shipped reducers (`R/ci-classical.R:109`,
      `:188`); write both tables.
- [x] T6 Assert both AC4 anchors; fill the page's Results section.
- [x] T7 Fill Disposition; append the verdict `D-entry`; correct the falsified
      `cairn/` records in place, marked and dated.
- [x] T8 Run `verify`, the four `data-raw/` checkers, `air format .`, lintr.
- [x] T9 Extend leg (b) to three `rho` with per-rho tolerances; add its
      mutations to the harness; commit `data-raw/m118-composition-spread.R`.

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
- 2026-08-14: review return 1 (defect) — AC2 fails inside the domain of the procedure it names. The AST fence never checks that `dist` is still the generator's PARAMETER, so `dist <- "gaussian"` as the body's first line satisfies all three clauses while every cell draws gaussian (reproduced at review: a nominal t5 cell yields pooled excess kurtosis -0.086). Also actioned: C6 the terminal-row rotation must land with the done-flip or CI reds; B1 D-030's "nothing in that amendment is falsified" is wrong about Amendment 1's closing clause; C10 the Results provenance sentence is false for the M111-block column.
- 2026-08-14: return fix — AC2's fence gains a clause 1b asserting no parameter of `gen_oneway` is rebound anywhere in its body (walked at any nesting depth, so a rebinding one indent down is the same defect). The mutation harness grows from 7 breaks to 11: the review's `dist <- "gaussian"` form, its nested-block variant, and rho- and n-rebinds. All 11 red, the unmutated script accepted.
- 2026-08-14: also closed A3 (scored 62, below the action bar) because its failure mode is a wrong population ICC under every coverage figure and the guard is cheap: a composition leg asserts `gen_oneway` recovers icc_hat within 0.10 of the cell's rho for all seven families. Mutation-verified — the real script's worst is 0.0727, `sd_a <- rho` gives 0.177 and `rep(a, times = n)` gives 0.540, so the tolerance sits between a measured legitimate spread and the nearest defect rather than on either.
- 2026-08-14: C10 fixed — the Results header claimed every figure re-derives from the sweep script, which is false for the M111 block's comparison column and counts (they come from the committed m116 table); the sentence now says which. The frozen page's two stale Evidence-snapshot lines are corrected by a dated note in Results rather than edited above, because a post-freeze edit there would cost the commit-order corroboration the freeze rests on (M113 lesson).
- 2026-08-14: B1/B2/B11/C1 fixed in D-030 — it no longer claims nothing in D-012 Amendment 1 is falsified (its closing "untested here" clause is spent, and the entry now says so), no longer credits D-012's scope fence with naming this gap, no longer attributes the searle preference to D-027, and states the stale-site set procedurally instead of as a hand-counted four.
- 2026-08-14: A11/B9 fixed — the INDEX line no longer restates 10 of 10, and its "ordered sign change" is restated as the per-family sign rule W1 actually is (C5); A12 hedged with the two measured non-monotone points.
- 2026-08-14: T9 done. Leg (b) now runs at rho 0.05/0.25/0.5 with per-rho tolerances 0.05/0.10/0.10, and both legs are mutation-verified by one harness: 11 fence mutations and 3 composition mutations, all red, both baselines accepted. `data-raw/m118-composition-spread.R` prints the legitimate spread (0.0288/0.0572/0.0727) beside each mutation's separation and asserts the property the tolerances must have — real inside every one, each mutation outside at least one — rather than leaving it to be eyeballed.
- 2026-08-14: the component swap is caught at 2 of 3 rho, and that is the whole reason leg (b) is not single-rho: at rho = 0.5 it reads 0.0727, identical to the real script, because 0.5 is the fixed point of rho <-> 1 - rho.
- 2026-08-14: the fence's `switch(dist` clause was rewritten on the AST rather than deleted — it checks that some `switch` in `draw_standard`'s body dispatches on the symbol `dist`, taking `EXPR =` and positional spellings alike. Deleting it (the first attempt) lost a real catch; as an AST check it keeps the catch and drops the lexical defect. It reads `draw_standard`'s body, not `gen_oneway`'s, so it sits outside what the amended AC2's clause (a) promises — kept because it is free, not because the criterion rests on it.
- 2026-08-14: full suite clean after the amendment — 7159 passing, 0 failures (down 7 from consolidating leg (b)'s per-family assertions into one call). Status → review for a third pass.
- 2026-08-14: amendment return: AC2 — "Two committed procedures bound that claim, both of them procedures over `gen_oneway` alone, and this criterion promises only what they decide." Amended wording audited by a fresh [O] reader before writing; user-approved at the mini gate. This consumes the first of AC2's two amendment slots.
- 2026-08-14: second review pass — an adversarial [O] reviewer defeated the fixed fence with 10 further mutations, all green against both test files. Independently reproduced two: `assign("dist", "gaussian")` leaves the fence green AND passes the composition leg at every rho (only the family is wrong, not the ICC); and swapping `sd_a`/`sd_e` has error 0.0727 at rho = 0.5 — identical to the real script, because 0.5 is the fixed point of rho <-> 1-rho — while giving 0.3227 at rho = 0.25 and 0.5227 at 0.05.
- 2026-08-14: that is the widening test, not a second defect. AC2 promises the test fails when a draw "resolves" to a normal deviate, a universal over program behaviours no AST walk enumerates; the round-1 repair answered one counterexample by widening a recall-fixed list of forms and `assign()` defeated the wider list at once. The repo's own precedent is M102's "no command reads git history", beaten in turn by a ref spelling, an argument-order bug and `awk`. Routing to the gated criterion amendment; the repair is to narrow the promise until a stated procedure settles it.
- 2026-08-14: F10, F11 fixed in place ahead of the amendment because they are a live contradiction between two records rather than a criterion question — the reference page still asserted "nothing in it is falsified" of D-012 Amendment 1 while the corrected D-030 said the opposite, and D-030's own replacement sentence misdescribed this grid as symmetric-only and single-rho when it carries chisq1 and reaches rho = 0.60. Both records now agree, and the D-027 mis-attribution is corrected on the page too (its frozen Consequence clause carries the same error and is left untouched, the dated note in Results carrying the correction instead).
- 2026-08-14: full suite clean after the fixes — 7166 passing, 0 failures (up 8 from the composition leg), same 3 deliberate warnings and 2 pre-existing skips. Status → review for a second review pass.
- 2026-08-14: status → in-progress. Every gate was clean — cairn_validate, devtools::check() (0/0/1 pre-existing NOTE), and four CI jobs green — so the return is the criterion, not the gate.
- 2026-08-13: post-audit consolidation merged the freeze pair into AC1 and the two anchors into AC4, clearing the >7-criteria tripwire; both merges concatenate audited text and were re-checked against the audit's three questions, with no claim added.

## Decisions

**2026-08-14 — D-030 corrected in place rather than by an appended amendment.**
Four errors in D-030 were actioned or logged at the review (B1, B2, B11, C1).
`DECISIONS.md` is append-only under IP4, and the repo's own precedent for a
wrong entry is an appended amendment (D-008 Amendment 1, D-012 Amendment 1). We
edited D-030 itself instead, on the ground that it has not merged: it was
authored by this milestone, sits only on `m118-width-reversal-grid`, and the
branch squash-merges, so no reader has ever seen the wrong text and no history
on the default branch is rewritten. The line this draws: once D-030 lands on the
default branch, any further correction takes an appended amendment. Recorded
here because the alternative reading — that a committed entry is history the
moment it is committed anywhere — is defensible, and a later reader should see
that the choice was made rather than overlooked.

**2026-08-14 — the terminal-row rotation is owed at the `done` flip, not now.**
Review finding C6 (85): `data-raw/record-claims.tsv` pins the ROADMAP's terminal
rows as exactly M117/M116/M115/M114/M113, and simulating M118's flip to `done`
yields six, which reds `check-references` on the next PR. The rotation cannot be
made now — M118 is not terminal until the post-merge hygiene commit — so it is
recorded here as owed work for that commit: rotate M113 out, add M118, and
update both the retention comment and the `record-claims.tsv` expectation **in
that same commit**. This is the M114 lesson, which `LESSONS.md` records this repo
hitting three times; the milestone that finds it is the one that must carry it.


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
- **AC2 — NOT MET (return).** Tick withdrawn 2026-08-14. `test-m118-both-components-dgp.R` passes 2/2.
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

### Independent review — three lenses, then a scorer (2026-08-14)

39 candidate findings from an [O] diff-bug lens, an [S] blame-history lens and
an [S] prior-review lens; all 39 scored by a fresh [S] scorer that generated
none of them. 4 actioned (≥ 80), none ≥ 90, 35 below the bar.

**Actioned — A1 (86), the return.** AC2's named procedure is a committed test
that walks the parsed body and fails when a component's draw resolves to a
normal deviate. Inserting `dist <- "gaussian"` as the first line of
`gen_oneway`'s body satisfies all three fence clauses — no RNG call in the body,
both components still passing the bare symbol `dist`, `draw_standard` still
switching on `dist` — so the fence stays green while every cell draws gaussian.
Reproduced at review: a nominal `t5` cell then yields pooled excess kurtosis
−0.086. Two sibling mutations are also green — `sd_a <- rho` and
`rep(a, times = n)` — and those corrupt the population ICC the coverage figures
are scored against, though `m118-anchor-checks.R` leg 2 would catch both.

**Actioned — C6 (85).** `data-raw/record-claims.tsv` pins the terminal ROADMAP
rows as exactly M117/M116/M115/M114/M113. Simulating the merge-time flip of
M118 to `done` yields six, so `check-references` reds on the next PR unless the
rotation and the expectation land in the same commit (the M114 lesson, hit three
times before).

**Actioned — B1 (82).** D-030 says nothing in `D-012 Amendment 1` is falsified.
Its ledger clause indeed stands, but Amendment 1's closing sentence — "it is
untested here because both repo grids draw only the subject effect" — is exactly
what this milestone falsifies. The T7 record sweep missed it.

**Actioned — C10 (80).** The Results header claims every figure re-derives by
re-running `m118-width-reversal-sweep.R`, but the M111 block's "subject-effect
only" column and its "(was N of 16)" counts come from
`m116-classical-width-comparison.tsv`. The figures are correct and
level-matched; the provenance sentence is not.

**Below the bar (35), logged not actioned.** A2 72 hard-coded family at the call
site is outside the fence's domain · A3 62 the located-and-scaled composition is
unfenced (anchor leg 2 would catch it) · A4 68 / C13 64 the mirrored fixture is
read by no test · A5 72 the M111-block aggregator is under-stated · A6 63 empty
`## Decisions` section · A7 64 the MSA=0 guard is mis-attributed to D-022 · A8
66 "Burch's own Fig. 2 design" over six families where the source names five ·
A9 68 / C9 66 false "both sizes a cell actually uses" comment · A10 72 / C3 68 /
C12 58 the frozen page's own Evidence snapshot is stale at HEAD · A11 68 / B9 68
INDEX restates a measured value · A12 62 "grows with the subject count in every
heavy-tailed family" is non-monotone at the top · A13 52 mixed rounding · A14 50
no NULL guard in the anchor script · A15 35 `n_rep` column ignores `n_skip` ·
B2 72 D-030 mis-credits D-012's scope fence · B3 60 W1's statistic differs from
the reopening condition's (verdict confirmed invariant) · B4 70 / C7 66 the
sibling fence test is a whole-file grep · B6 45 dropped "not refuted" hedge ·
B7 66 the burch2011 correction discloses one of two edited clauses · B8 66 the
new dated claim carries no settling directive · B10 45 the deferral to M119 is
what the plan called for · B11 72 D-030 mis-cites D-027 for the searle
preference · B12 50 imprecise freeze-ordering phrasing · C1 66 D-030's
"four surfaces" is a hand-list · C2 50 M119's scope list, disclaimed by its own
AC1 · C4 72 the snapshot's directive enumerates two files for an all-grids claim
· C5 62 "ordered sign change" in INDEX · C8 72 fence clause 3 is a lexical match
on deparsed text · C11 42 reported-not-asserted figures, as designed.

**Gate results (all clean; the return is the criterion, not the gate).**
`cairn_validate` 16 PASS / 8 advisory OK. `devtools::check()` 0 errors,
0 warnings, 1 NOTE — the pre-existing long-running-tests note this suite has
always carried, not introduced here. CI on the review commit: `lint`,
`check-references`, `format-check`, `pkgdown` green.
