# M92: Off-node S coverage probe for `ci_method = "mpl"` at the shipped `conf_level = 0.95`

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6, GP7
- **Branch/PR:** `m92-mpl-095-interp-probe` · https://github.com/jmgirard/intraclass/pull/99

## Goal

Close the one interpolated-S evidence gap M91 left: give `mpl_kappa_lookup()`'s
linear-in-S interpolation coverage evidence at the DEFAULT `conf_level = 0.95`,
where every cell ever swept has sat on an `s_grid` node.

## Scope

**In:** three frozen off-node-S coverage cells at 0.95 (E1–E3 below), pre-registered
before any run (GP5) into `cairn/references/mpl-twoway-random-comparison.md`; a
seeded `data-raw/` sweep script + committed fixture, per-cell `role` asserted against
geometry; the frozen verdict APPLIED, including the shortfall consequence; the
`R/ci-mpl.R` interpolation comment and the `ci_method`/`conf_level` docs restated to
the measured status; both affected ROADMAP candidate rows resolved.

**Out:** re-probing 0.90/0.99 (M91's D1–D3 confirmed those; no new evidence here
changes them) · a monotone smoother over the whole κ_m table, or a bracket-max rule at
0.90/0.99 → stays the ROADMAP envelope candidate, promoted only on evidence at those
levels · re-calibrating any κ_m value → M90's tables are frozen inputs · off-grid
(R,S) extrapolation → still aborts, D-015 · on-the-fly calibration → candidate row.

## Acceptance criteria

- [x] AC1 (GP5): the E1–E3 pre-registration — geometry, floor, `n_rep`, role, and the
      shortfall consequence — is committed to
      `cairn/references/mpl-twoway-random-comparison.md` in a commit strictly EARLIER
      than the one adding any result, demonstrable from `git log` on the two paths.
- [x] AC2: a committed seeded script writes a fixture in which each cell's `role` is
      asserted against its geometry (a `stopifnot` mirroring
      `data-raw/m91-mpl-interp-sweep.R:94-98`), and the 0.95 verdict reports
      `interp_ok` as a measured value — never an aggregate over mixed-role cells
      (M91 finding F1).
- [x] AC3 (GP6): E1, E2 and E3 each report coverage with an exact binomial CI against
      the frozen floor, and the recorded verdict is the frozen rule applied — no floor
      moved after seeing a result.
- [x] AC4: the frozen shortfall consequence is executed as written — if any cell falls
      below its floor, `mpl_kappa_lookup()` uses the bracket-max rule for off-node S at
      0.95 only, every 0.95 NODE lookup stays bit-identical to today, and the failing
      cell re-runs above its floor; if none falls short, the lookup is unchanged.
- [ ] AC5 (GP7): every in-repo statement about interpolated-S evidence at 0.95 —
      `R/ci-mpl.R`'s interpolation comment, the `@param ci_method`/`conf_level` text,
      and the comparison note — matches what the shipped fixture carries, with a
      test pinning the property the code relies on.
- [x] AC6: the ROADMAP "off-node S coverage probe at 0.95" candidate is absorbed, and
      the "κ_m monotone envelope / smoother" candidate is updated with this
      milestone's evidence (or dropped, if superseded by the applied consequence).
- [x] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; and both
      references-CI checkers green — `enumerate-generalizing-claims.py --check` and
      `check-reference-observations.py` (M85/M86: `cairn_validate` runs neither, and a
      `check:` directive must settle with python3/shell/git, never `Rscript`).

**Frozen cells** (δ = 4, ρ = 0.60, level 0.95, floor ≥ 0.93, `n_rep` 1000 each — the
0.95 posture M91 used for D4; κ_m from the shipped table):

| cell | R | S | bracket κ_m | why this geometry |
|---|---|---|---|---|
| E1 | 3 | 25 | 0.632 → 0.786 (20→30) | the exact twin of M91's D1 (0.90) / D2 (0.99) — completes the level triple |
| E2 | 10 | 40 | 0.186 → 0.118 (30→50) | the worst 0.95 dip (−0.068); largest RELATIVE error in the `1 + κ_m` scaling the deviance critical value |
| E3 | 2 | 40 | 1.267 → 1.466 (30→50) | large-κ_m CONCAVE bracket, so the chord sits below the curve — the under-covering direction; D3's geometry at the shipped level (corrected T6: not the slice's largest κ_m — R=2, S 50→100 is higher) |

**Frozen shortfall consequence:** a cell below its floor switches
`mpl_kappa_lookup()` at conf_level 0.95 to the **bracket-max rule** — an off-node S
takes `max()` of its two bracketing node values instead of the linear chord, which is
≥ the chord everywhere so the interval only ever widens, and leaves every node lookup
untouched (preserving M91's bit-identical 0.95 node property). The failing cell then
re-runs at the same `n_rep` against the same floor.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2, T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T3, T4, T5, T6

## Tasks

- [x] T1: Write and commit the E1–E3 pre-registration into
      `cairn/references/mpl-twoway-random-comparison.md` (mirroring the § M91 block at
      line 433) — cells, floors, `n_rep`, roles, the criterion, and the bracket-max
      shortfall consequence — as a standalone docs commit BEFORE any script runs. Any
      settling directive uses python3/shell/git only.
- [x] T2: Add `data-raw/m92-mpl-095-interp-sweep.R`, modelled on
      `data-raw/m91-mpl-interp-sweep.R` — same `m86-mpl-lib.R` machinery, κ_m taken
      through the interpolation rule under test, per-cell seed stride, the role
      `stopifnot`, and `interp_ok = NA` where a level has no off-node cell. Smoke-run
      it first (`M92_SMOKE=1`).
- [x] T3: Run the sweep (~15 min), commit `data-raw/m92-interp-sweep.rds`, and record
      the applied verdict per cell in the work log.
- [x] T4: Execute the frozen consequence. No shortfall → add a test pinning that a
      0.95 off-node lookup equals the linear chord. Shortfall → implement bracket-max
      for 0.95 off-node S in `R/ci-mpl.R`, add tests that every 0.95 node lookup is
      unchanged and off-node values only widen, re-run the failing cell, and add a
      NEWS entry for the widened interpolated intervals.
- [x] T5: Restate the interpolated-S evidence status at every site that claims it —
      `R/ci-mpl.R`'s interpolation comment, `@param ci_method` / `@param conf_level` in
      `R/icc.R`, and the comparison note — then `devtools::document()`.
- [x] T6: Resolve both ROADMAP candidate rows, run the full AC7 gate (including the
      two references checkers), and open the PR.
- [x] T7 (review finding F1, 87): make the sweep's seed span disjoint from M91's,
      re-run all three cells, keep the superseded run committed, and rewrite every
      independence/monotonicity claim to what the new fixture supports.
- [x] T8 (review finding F3, 92): correct the "largest 0.95 kappa_m" over-claim in
      `data-raw/m92-mpl-095-interp-sweep.R`'s header — the fifth site T6 missed.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the M91-review-F1 candidate; plan gate froze three cells — the D1/D2 twin, the worst 0.95 dip, and the largest-κ_m geometry — and chose the bracket-max rule over node-restriction as the shortfall consequence, so no currently-working call breaks).
- 2026-07-25: T1 done — § M92 pre-registration frozen in `mpl-twoway-random-comparison.md` (E1–E3, floors, criterion, bracket-max consequence + why it departs from § M91's node-restriction for the shipped level); its dated observation carries a python3-only settling directive, mutation-verified to exit 1 when D4's S is changed off-node; 5 generalizing-claim candidates triaged `OUT-repo-analysis` by generated rows; both references checkers green.
- 2026-07-25: T2 done — `data-raw/m92-mpl-095-interp-sweep.R` added; mirrors the M91 generator (m86-mpl-lib machinery, per-cell seed stride, role `stopifnot`) and adds two extra assertions (no cell on an `s_grid` node, every cell at 0.95) plus an `M92_RULE=linear|bracketmax` switch so the pre-registered shortfall re-run uses the same generator. Smoke run clean; air + lintr clean; no citekey named, so no D-009 directive is re-tripped.
- 2026-07-25: T3 done — sweep run, `data-raw/m92-interp-sweep.rds` committed. All three cells clear the frozen 0.93 floor under the SHIPPED linear rule, so the pre-registered bracket-max consequence is NOT triggered: E1 (R=3,S=25) κ_m 0.7089 cov 0.9680 [0.9551, 0.9780] miss 32/0; E2 (R=10,S=40, the worst 0.95 dip) κ_m 0.1517 cov 0.9530 [0.9380, 0.9653] miss 34/13; E3 (R=2,S=40, largest κ_m) κ_m 1.3663 cov 1.0000 [0.9963, 1.0000] miss 0/0. `interp_ok = TRUE` at 0.95 on three off-node cells, no mixed-role aggregation.
- 2026-07-25: T4 done — no-shortfall branch taken, so `mpl_kappa_lookup()` is UNCHANGED and bracket-max is not adopted. Added the M92 AC5 pin in `tests/testthat/test-ci-mpl.R`: the three coverage-validated 0.95 constants (0.7089067 / 0.1517143 / 1.3663359) plus an assertion that S = 25 and S = 40 are genuinely off-grid. Checked the pin discriminates the two rules rather than only a table edit — bracket-max would give 0.7862854 / 0.1857780 / 1.4656788 at the same geometries, so all three literals red under the alternative. No NEWS entry for a behaviour change: none happened.
- 2026-07-25: T5 done — restated the evidence status at five sites: `R/ci-mpl.R`'s GP7 interpolation comment (0.95 now confirmed, with the three cells and the untriggered consequence named), `@param ci_method` in `R/icc.R` (adds the interpolated-path guarantee), `NEWS.md` (same, user-facing), the note's new § M92 verdict, and § M91's now-false standing claim that 0.95 remains unprobed — corrected in place and marked superseded, not rewritten (D-045). Also narrowed the one-sidedness wording everywhere it appeared: E2 measured 34/13 at R = 10 against D1's 65/1 at R = 3, so the blanket reading was wrong. `document()` re-run (man/icc.Rd), ledger refreshed (1 orphan row dropped, 5 added), both references checkers + cairn_validate green, 169 mpl tests pass.
- 2026-07-25: correction (supersedes the "largest κ_m" wording in the plan-gate and T3 entries above, which are history and stay as written). Ran the M72 self-check — grep own new prose for counts and universals, re-derive each against the source — over everything this milestone wrote. E2's "worst 0.95 downward step" holds (−0.0681 at R=10, S 30→50 is the most negative in the slice). **E3's "largest κ_m at 0.95" does not**: `(R=2, S 50→100)` is higher at 1.4657 → 1.6245 and the slice maximum is 1.6245 at `(2, 100)`. E3 is the largest-κ_m cell THIS pass sweeps, on a concave bracket, at D3's geometry — which is the real reason it was chosen. Corrected at all four live sites (pre-registration bullet + cells row, § M92 verdict, `R/ci-mpl.R`, the AC table), marked in place per D-045; cells, floors and `n_rep` untouched, so the frozen bar is unchanged (GP5).
- 2026-07-25: T6 done — envelope candidate row updated with M92's evidence (two passes now find no coverage cost to the dips; promote only on a NEW failure); the probe candidate was already absorbed at the plan gate. Gate: `devtools::check(env_vars = c(NOT_CRAN = "false"), manual = FALSE)` → Status OK, 0 errors / 0 warnings / 0 notes; full suite at `NOT_CRAN=true CI=true` → FAIL 0, PASS 4210, SKIP 23, WARN 2 (pre-existing glmmTMB convergence warnings on the multilevel path — verified not ours: `git diff main..HEAD -- R/` changes zero non-comment lines); air + lintr clean; `document()` no-diff; both references checkers and cairn_validate green. AC1 ordering verified from git log: pre-registration da10025 (08:55:23) precedes the first result 2b984af (08:58:08). Manual built with `--no-manual` locally (known TinyTeX Courier font gap, not an Rd problem); CI builds it.
- 2026-07-25: all tasks done, gate clean; PR #99 opened, status -> review.
- 2026-07-25: review FAILED at AC5, status -> in-progress. What failed: finding F1 (scored 87) — the sweep's `seed_base` 20260725 against M91's 20260724 at the same stride and cell order makes E1 and E3 re-simulate M91's D1/D3 datasets bit-for-bit (verified: `mpl_simulate` `identical()` at the aligned seeds), so the shipped "second independent look" / "two independent passes" / "second probe's worth of evidence" claims are not what the fixture carries, and the D1->E1 "monotone in the level" item is forced by crit(E1) > crit(D1) on shared data. Riding along: F3 (92) — the corrected "largest 0.95 kappa_m" over-claim is still live at `data-raw/m92-mpl-095-interp-sweep.R:22-25`, a fifth site the T6 entry's "all four live sites" missed. AC1-AC4, AC6, AC7 verified and stay ticked; AC5 unticked. Four findings scored below 80 are logged in the Review section, not actioned.
- 2026-07-25: minor plan amendment — added T7 and T8 for the two actioned review findings (discovered sub-tasks; no criterion, scope or goal text changed).
- 2026-07-25: T7 done (F1). `seed_base` 20260725 -> 20920725, chosen so M92's seed span is disjoint from M91's; added a `stopifnot` that recomputes M91's span from ITS committed constants and asserts zero intersection, mutation-verified to error when the old base is restored. Guard pins the FROZEN n_rep 1000, not `cells$n_rep`, so smoke mode cannot relax it. Run 1 preserved at `data-raw/m92-interp-sweep-run1-collided.rds`; re-run written to `data-raw/m92-interp-sweep.rds`. New numbers: E1 0.9670 [0.9540, 0.9772] miss 31/2; E2 0.9440 [0.9279, 0.9574] miss 42/14; E3 0.9990 [0.9944, 1.0000] miss 0/1 — all three still clear the frozen 0.93 floor, and kappa_m is bit-identical across runs (table-derived, not run-derived). GP5 posture recorded explicitly in the note: run 1 ALSO cleared every floor, so no floor result motivated the re-run — the defect was reproducibility, not outcome.
- 2026-07-25: T8 done (F3) — generator header now states E3 is a large-kappa_m CONCAVE bracket and names the actually-larger (R=2, S 50->100) bracket and the 1.6245 slice maximum, with the correction dated.
- 2026-07-25: also fixed three sub-80 findings opportunistically while editing the same lines, each verified true first and each noted as such rather than folded in silently — F2 (68): `@param ci_method` no longer attributes the one-sidedness difference to rater count, since the two cited cells differ in R, S and level together; F4 (78): "same evidential footing" -> the interpolated path is coverage-CHECKED at each level at a handful of geometries, while nodes are individually CALIBRATED; F5 (62): added a non-midpoint pin (R=3, S=22 -> 0.6624794) plus an explicit refutation that the value equals the bracket mean, so the test now discriminates any bracket-symmetric rule, not just bracket-max. F6 (35) deliberately left alone — a repo-wide convention inherited from M91's generator, out of M92's scope.
## Decisions


## Review

Reviewed 2026-07-25 on `m92-mpl-095-interp-probe` @ PR #99. `main` had not moved
since the branch was cut (0 commits behind), so all evidence is against a current base.

**AC1 (GP5 — pre-registration precedes results).** VERIFIED by `git log` on the two
paths: the pre-registration lands in `da10025` (commit time 1784987723), the first
result fixture in `2b984af` (1784987888) — strictly earlier, 165 s apart. Stronger
check run beyond the criterion: `git show da10025:...` against HEAD shows the frozen
bar (R, S, δ, ρ, level, floor ≥ 0.93, `n_rep` 1000) **byte-identical** for all three
cells; only E3's rationale prose changed, as the documented T6 correction.

**AC2 (role asserted, `interp_ok` measured).** VERIFIED against the committed fixture:
all three cells off-node (`n_s` ∉ {10,15,20,30,50,100}) → TRUE, all roles `interp` →
TRUE, and `verdict[["0.95"]]$interp_ok` is the logical TRUE over `interp_cells` =
E1, E2, E3 — a measured value over three same-role cells, not an aggregate across
mixed roles. The script's own `stopifnot` (m92-mpl-095-interp-sweep.R:125-131) asserts
the role labels against geometry and additionally that no cell sits on a node.

**AC3 (GP6 — coverage with exact CI against the frozen floor).** VERIFIED:
E1 0.9680 [0.9551, 0.9780]; E2 0.9530 [0.9380, 0.9653]; E3 1.0000 [0.9963, 1.0000];
floor 0.93 and `n_rep` 1000 on every cell, matching the pre-registration exactly;
`all(adequate)` TRUE, `failed_cells` empty. Rule recorded in the fixture is `linear`
— the shipped rule, so the frozen bar was applied, not a substitute.

**AC4 (frozen consequence executed).** VERIFIED — no-shortfall branch. Zero cells
below floor, so bracket-max was not adopted. `git diff main..HEAD -- R/` filtered to
non-comment lines is **empty**: the runtime lookup and every other code path are
untouched, which is the strongest available form of "the lookup is unchanged".

**AC5 (statements match the fixture; a test pins the property).** **FAILED** — see
finding F1 below; the sub-check recorded here passed but does not cover the claim F1
falsifies. Three live
claim sites — `R/ci-mpl.R:217` (0.968 / 0.953 / 1.000 named per cell), `R/icc.R:351`
and `NEWS.md:79` (interpolated path validated at all three levels) — each check out
against the fixture and against M91's D1–D3 for the other two levels. The pin is
`test-ci-mpl.R:631`, and it discriminates the two candidate RULES rather than only a
table edit: bracket-max would return 0.7863 / 0.1858 / 1.4657 at the same geometries
against the pinned 0.7089 / 0.1517 / 1.3663.

**AC6 (candidate rows resolved).** VERIFIED: the "off-node S coverage probe at 0.95"
row is absent from `cairn/ROADMAP.md` (absorbed at the plan gate), and the κ_m
envelope/smoother row now carries M92's evidence and its `→ M92 T3` lineage —
narrowed to "promote only on a NEW failure", since two independent passes have now
found no coverage cost to the dips.

**AC7 (full gate).** VERIFIED, fresh at review:
`devtools::check(env_vars = c(NOT_CRAN = "false"))` → Status OK, 0 errors / 0 warnings
/ 0 notes (2m 20.7s). Full suite at `NOT_CRAN=true CI=true` → FAIL 0, PASS 4210,
SKIP 23, WARN 2 (pre-existing glmmTMB convergence warnings; `git diff main..HEAD -- R/`
changes zero non-comment lines, so not from this diff). `lintr::lint_package()` 0 lints;
`air format --check .` clean; `devtools::document()` no-diff; `pkgdown::check_pkgdown()`
"No problems found"; `enumerate-generalizing-claims.py --check` and
`check-reference-observations.py` both green. CI on `af6aff2`: 9/9 green.

**Consistency gate.** `cairn_validate.py` exit 0 — every check PASS. Coverage-completeness
included, so the plan's criterion→task map is intact. No `DESIGN.md` principle changed,
so `cairn_impact` is a clean no-op. Profile `consistency-gate` slot run in full above.

## Review findings

Three fresh-context lenses + an independent scorer.
**Blame-history [S]: zero findings.** **Prior-review [S]: zero findings**
(the `gh api .../pulls/comments` probe returned `[]`, so archived `## Review` sections
were the evidence base — the expected shape for this repo). **Diff-bug [O]: six
findings**, scored 87 / 68 / 92 / 78 / 62 / 35.

### Actioned (score ≥ 80)

**F1 (87) — `data-raw/m92-mpl-095-interp-sweep.R:141-142`: the seed scheme silently
re-runs M91's exact datasets, so "second independent look" is false for two of three
cells.** `seed_base <- 20260725L` with the same `seed_stride <- 1000000L` and the same
cell ordering as M91's generator (base `20260724L`) makes M92 cell `ci` rep `r` use the
*same integer seed* as M91 cell `ci` rep `r+1`. E1 (ci=1, R=3, S=25) shares 999 of 1000
datasets with D1; E3 (ci=3, R=2, S=40) draws entirely inside D3's 2000. Only E2 is new
data. **Verified here independently**: `mpl_simulate` at the aligned seeds is
`identical()` TRUE for both pairs at several reps. Consequences — the "second
independent look" (note § M92 verdict), "two independent passes" (ROADMAP candidate row)
and "a second probe's worth of evidence" (`R/ci-mpl.R`) claims are unsupported; and the
note's "0.934 (D1, 0.90) → 0.968 (E1, 0.95) … monotone in the level" item is
arithmetically forced on shared data, since `crit = (1+κ)·qchisq(1−α,1)` is larger at E1
(6.56) than D1 (4.81), so E1's interval contains D1's on every shared rep. The per-cell
coverage numbers stand; the independence and controlled-triple framing does not.

**F3 (92) — `data-raw/m92-mpl-095-interp-sweep.R:22-25`: the false "largest κ_m"
superlative T6 corrected everywhere else is still live in the committed generator.**
The header still reads "E3 crosses the largest 0.95 kappa_m (1.2670 -> 1.4657 over the
same nodes)" and "there the absolute error is largest". Both false: the slice maximum is
1.6245 at (R=2, S=100) and the (2, 50→100) bracket is higher and wider. The T6 work-log
entry claims correction "at all four live sites"; this is an uncorrected fifth, in the
file the note names as generator of record. **Verified here**: the strings are present.

### Logged, not actioned (score < 80 — surfaced, never silently dropped)

- **F2 (68)** — `R/icc.R:357-361`: the new rater-count claim compares M91's D1
  (conf_level 0.90, S=25, R=3) with E2 (0.95, S=40, R=10), so three factors vary while
  the sentence credits rater count. Real but narrow; no committed fixture isolates the
  rater axis.
- **F4 (78)** — `NEWS.md:80-81`, `R/icc.R:351-353`: "the same evidential footing"
  overstates — nodes are each individually calibrated, interpolated values nowhere, and
  only six (R,S,level) off-node points have ever been coverage-checked.
- **F5 (62)** — `tests/testthat/test-ci-mpl.R:645-659`: all three pinned S values are
  exact bracket midpoints, so the pin cannot distinguish linear from any
  bracket-symmetric rule (R=3, S=22 → 0.6625 linear vs 0.7089 bracket-mean). It does
  discriminate the pre-registered bracket-max alternative, which is what the work log
  claimed, so the gap is narrower than the finding framed it. **Verified here.**
- **F6 (35)** — `data-raw/m92-mpl-095-interp-sweep.R:169-173`: the `tryCatch` fallback
  returns `c(lower=0, upper=1)`, scoring an errored fit as covered. Byte-identical to
  M91's shipped generator and a repo-wide convention, and no rep errored in this run.

### Gate outcome

**AC5 fails as written.** F1 falsifies an in-repo statement about the 0.95 evidence, and
AC5 requires every such statement to match what the shipped fixture carries. Per the
review rules a criterion failure returns the milestone to `in-progress` — the criterion
is not reinterpreted and nothing merges. F3 rides along in the same send-back.
