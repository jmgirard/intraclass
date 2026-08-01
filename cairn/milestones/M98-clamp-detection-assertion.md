# M98: Assert the endpoint-parity test's clamp-detection classes, and add the non-finite one

- **Status:** review
- **Priority:** normal
- **Depends on:** M93
- **Driving RR:** —
- **Principles touched:** GP5, GP7
- **Branch/PR:** `m98-clamp-detection-assertion` · https://github.com/jmgirard/intraclass/pull/106

## Goal

Make the AC4 endpoint-parity test's ability to detect post-processing in
`icc()`'s reporting path asserted per clamp class, rather than incidental to
whichever endpoints the grid's cells happen to produce.

## Scope

**In:** The AC4 grid of `tests/testthat/test-boundary-abort-hint.R`
("verification inspects exactly the endpoints `icc()` reports"). Two additions.
(1) A **per-class assertion** replacing the `out_of_support_seen` flag the
2026-08-01 pole hotfix deleted without replacement: detection currently rests on
cells that nothing pins, which is how high-side detection was lost silently.
(2) A seed-free cell supplying the one clamp class no cell covers — a
**non-finite** reported endpoint — from SSA = 0 balanced one-way data
(`bh_degen_between()`, `searle`), measured through `icc()` on 2026-08-01:
`unit = "average"` and `unit = 3` → `[-Inf, -Inf]`, `unit = 2` → `[-2, -2]`,
`unit = "single"` → `[-0.5, -0.5]`. Plus mutation evidence that the new cell
adds detection the grid did not have, and a truthful rewrite of the comment
recording what is and is not covered.

**Out:** High-side (`pmin(1, .)`) detection — unreachable through any shipped
`ci_method` since the pole hotfix, so a probe needs a synthetic reducer or an
injected endpoint, neither of which exercises the reporting path this test
exists to pin → ROADMAP candidate row, written by this plan. Any change to
shipped behavior, `R/` guards, roxygen, or NEWS → test-only milestone; a guard
change would be its own hotfix.

## Acceptance criteria

- [x] AC1 The AC4 grid reaches the numeric reducer-vs-`icc()` comparison
      (`tolerance = 0`) on at least one cell whose reported `conf.low` is
      **non-finite**, supplied by a **seed-free** fixture. No cell does at HEAD.
- [x] AC2 The test asserts **per class** that a compared cell exists with (a) a
      finite `conf.low` strictly below −1 and (b) a non-finite `conf.low`. Each
      assertion reds when its own class is removed from the grid — established
      by removal, not by inspection, and recording that the **class assertion
      itself** failed, since removing a cell also reds the count literals.
- [x] AC3 Mutation evidence at the reporting-path assembly (`R/icc.R:2209`),
      recorded from real runs: a clamp binding **only** on non-finite endpoints
      passes at HEAD and reds after this milestone; `pmax(-1, .)` and
      `pmax(0, .)` red both before and after. The first leg is the one that
      establishes the new cell adds detection rather than duplicating it.
- [x] AC4 The `checked` / `compared` exact-count assertions are updated as
      integer literals — never expressions derived from `cases`, which would
      self-adjust and assert nothing — and still red on a silently dropped
      cell, verified by removing one unit from the new case.
- [x] AC5 The comment heading these cells states truthfully which clamp classes
      the grid detects and which cells supply each — recording that the
      finite-below-−1 class had a single, **seeded** supplier at HEAD (the
      npbootstrap `unit = "average"` cell, `seed = 4`) and that this milestone's
      SSA = 0 `unit = 2` cell adds a **seed-free** second supplier of the same
      class; that low-side detection predates this milestone and was unasserted;
      and that high-side detection is unreachable through any shipped
      `ci_method`. Endpoints below −1 or
      non-finite are **not** called "out of support" — under D-010 the
      projected form's support is `(-Inf, 1)`, so the honest phrase is outside
      the conventional `[-1, 1]` range.
- [x] AC6 The PROFILE `verify` slot is clean — `devtools::test()` at
      `NOT_CRAN=true CI=true` for gate parity — plus `lintr::lint_package()`
      clean and `devtools::check()` clean run with
      `env_vars = c(NOT_CRAN = "false")`, or the live-Stan brms suite runs
      inside the check.

## Coverage

- AC1 → T1
- AC2 → T2, T4
- AC3 → T3
- AC4 → T2, T4
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1 Add the seed-free SSA = 0 `searle` case to the `cases` list
      (`test-boundary-abort-hint.R:2062`) with its own `units` list —
      `"single"`, `"average"`, `2`; `unit = 5` is excluded deliberately, it
      refuses on both sides and would be a second refusal cell the `compared`
      count does not admit. Record the reported endpoints from a real run.
- [x] T2 Add the two per-class assertions in place of the deleted
      `out_of_support_seen` flag; update the `checked` / `compared` counts
      (`:2170-2180`) as integer literals — 23/22 today, expected 26/25 with the
      new case's three units, but measure rather than assume.
- [x] T3 Mutation-prove AC3's three legs at `R/icc.R:2209`, restoring the file
      after each; paste the pass/red lines into the work log.
- [x] T4 Removal checks: drop **every** supplier of each class in turn and
      confirm the matching assertion reds — recording that the class assertion
      itself failed, not merely that the file went red; drop one unit and
      confirm the count assertion reds; restore.
- [x] T5 Rewrite the comment block (`:2073-2087`) to the post-M98 state per AC5.
      REOPENED at review return 1: every figure in the ledger must be MEASURED
      against the final grid, not carried from the plan or the candidate row —
      the `pmax(0, .)` line (13 cells post / 10 pre, true min −2.533756) and the
      `pmax(-1, .)` supplier list (three, incl. the `-Inf` cell, since
      `pmax(-1, -Inf)` is `-1`). Fix F3's `unit = 5`/`6` slip in the same pass.
- [x] T6 Gate: `air format .`, `lintr::lint_package()`, `devtools::test()` at
      `NOT_CRAN=true CI=true`, `devtools::check()` with
      `env_vars = c(NOT_CRAN = "false")`.

## Work log

- 2026-08-01: created by /milestone-plan.
- 2026-08-01: criteria audit ([O], fresh context) returned four findings on the first draft; AC3's third leg ("with the new case removed, both mutations pass") was UNSATISFIABLE because `pmax(-1, .)` and `pmax(0, .)` already red at HEAD via pre-existing cells, which falsified the draft's whole premise that the hotfix left no low-side detection — verified by measuring the grid (npbootstrap `average` −2.5338 at `seed = 4`, and zero non-finite endpoints anywhere); also the "out-of-support" label contradicts D-010, AC4 goes vacuous if the counts become derived expressions, and AC6 conflated the `verify` and `consistency-gate` PROFILE slots; all four fixed at the gate and the milestone re-cut around the assertion and the non-finite class.
- 2026-08-01: plan gate chose a seed-free SSA = 0 cell routed through `icc()` over injecting an out-of-support endpoint into a direct reducer call because the property being pinned is the reporting path and a direct reducer call never exercises it; falsified by evidence that no shipped `icc()` path can produce a non-finite reported endpoint from a seed-free fixture.
- 2026-08-01: plan gate chose per-class assertions over one combined out-of-range assertion because a combined form still passes on a grid that has lost the non-finite class — the silent-loss mode this milestone exists to close; falsified by a measured loss the combined form catches and the split does not distinguish.
- 2026-08-01: plan gate routed high-side (`pmin(1, .)`) detection to a candidate row over including it here because every available probe would bypass the reporting path; falsified by a shipped `ci_method` that can again report an endpoint above +1.
- 2026-08-01: CHECKPOINT (now closed by the entry below) — a second criteria-audit pass over the re-cut criteria was dispatched and had not returned when the plan was first committed (`9e94bac`).
- 2026-08-01: second criteria audit returned all six criteria SATISFIABLE and confirmed the three pressure-tests: no cell in the grid reports a non-finite `conf.low` at HEAD (the `mpl` row reports exactly `0` at all four units; the pole cell aborts on both sides); T4's removals are temporary-and-restore so the exact-count doctrine is untouched; and a non-finite-only clamp at `R/icc.R:2209` does red after the new cell, because it changes only the `icc()` side while `searle_ci` still returns `-Inf`, with the clamp inert suite-wide (the only other `-Inf` mentions, `test-ci-npbootstrap.R:179` and `test-ci-npbootstrap-unbalanced.R:146`, are abort tests that never reach a reported endpoint).
- 2026-08-01: CORRECTION to the first audit entry above, caught by the second audit and confirmed by re-measuring — the figures "`bnd30x5 searle average` −1.296, `unit = 6` −2.100" were produced by a probe script that FABRICATED `bh_oneway()` (seed 2, invented construction) instead of reading the real fixture at `test-boundary-abort-hint.R:18` (seed 1, `s2s = 1e-6`); the real values are −0.397034 and −0.517537, and no `searle`/`burch` cell reaches below −1. Consequence for this plan: the finite-below-−1 class has exactly ONE supplier at HEAD — the npbootstrap `unit = "average"` cell at `seed = 4` — so detection of that class rests entirely on a seeded bootstrap cell, which AC5 must state and which strengthens rather than weakens the case for asserting it. The commit message of `9e94bac` carries the same wrong "three cells" claim and cannot be rewritten; this entry is the correction of record.

- 2026-08-01: status in-progress, branch `m98-clamp-detection-assertion` cut from `fbd6bfa`; no implementation question gate — the plan settled T1's units list, T3's three mutation instances and AC5's content, leaving nothing genuinely open.

- 2026-08-01: T1+T2 landed in ONE checkpoint (minor amendment) — T1 alone leaves the count literals stale and the suite red, so the profile's "verify clean before check-off" rule cannot be satisfied at a T1-only boundary. Measured endpoints for the new case, reducer and `icc()` identical at `tolerance = 0`: `single` −0.5/−0.5, `average` −Inf/−Inf, `2` −2/−2. Counts moved 23→26 `checked`, 22→25 `compared`, written as integer literals (the prior `length(units) * 5L + …` form was derived, which AC4 forbids). Verify slot clean: FAIL 0 | WARN 2 | SKIP 23 | PASS 5427.

- 2026-08-01: T3 mutation legs run at `R/icc.R:2209`, pre-M98 grid (`acd5610`'s test file) vs post-M98, `R/icc.R` restored after each and the tree verified clean. Non-finite-only clamp `ifelse(is.finite(x), x, -1e6)`: PRE 0 failed → POST 1 failed — the discriminating leg, so the new cell is what carries non-finite detection. `pmax(-1, x)`: PRE 1 → POST 3. `pmax(0, x)`: PRE 10 → POST 13. The PRE count of exactly 1 for `pmax(-1, .)` independently corroborates the second audit's finding that the finite-below-−1 class had a single supplier at HEAD.

- 2026-08-01: SUBSTANTIVE AMENDMENT (gated, user-approved) — AC5 was false as written once T1 landed. It required the comment to name the npbootstrap `unit = "average"` cell as the SOLE supplier of the finite-below-−1 class, but the new case's `unit = 2` cell reports −2, a finite value below −1, so post-M98 that class has two suppliers and the second is seed-free. AC5 now records the HEAD state (one seeded supplier) and the change (a seed-free second one); the alternative of narrowing the new case to drop `unit = 2` was offered and declined, since it would discard a free de-risking of the class that was most fragile. T4 amended in consequence: a class's removal test must drop EVERY supplier, not one cell.

- 2026-08-01: T4 removal checks, each restoring the file afterwards and the tree verified clean. Dropping BOTH class-(a) suppliers (npbootstrap `average` and the SSA = 0 `unit = 2`) fails `Expected seen_finite_below_neg1 to be TRUE` at `:2219` alongside the two count literals; dropping the sole class-(b) supplier (SSA = 0 `average`) fails `Expected seen_nonfinite to be TRUE` at `:2220` alongside the counts; dropping one unit fails the counts ALONE at `:2205`/`:2212` with both class assertions still passing, which shows the count assertion is load-bearing independently of the class census. The named-assertion failure in each case satisfies the second audit's confounding caveat — the class assertion itself failed, not merely the file.

- 2026-08-01: T5 rewrote the comment to a per-class ledger — which mutation each class corresponds to, which cells supply it, and the measured values — plus the reason the class assertions exist (the high side had none, so its only supplier was removed silently) and the D-010 wording fence (below the conventional [-1, 1] range, never "out of support"). Every figure in it is measured, none carried over from the plan. `air format .` clean; file re-run green.

- 2026-08-01: T6 gate clean — `air format --check .` silent, `lintr::lint_package()` clean, `devtools::test()` at `NOT_CRAN=true CI=true` FAIL 0 | WARN 2 | SKIP 23 | PASS 5427, `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes in 2m47s. Status → review.

- 2026-08-01: REVIEW RETURN 1 — AC5 fails. The comment's `pmax(0, .)` ledger line (`test-boundary-abort-hint.R:2088`) states "eight boundary cells, min -0.5855"; measured, 13 cells detect that mutation post-M98 (10 pre) and the true minimum `conf.low` is −2.533756. The figure was carried from the ROADMAP candidate row rather than measured, which also falsifies T5's own work-log claim that every figure in the comment was measured. F5 (78, logged) should be fixed in the same pass: `pmax(-1, -Inf)` is `-1`, so the `-Inf` cell supplies that class too — three suppliers, matching T3's measured POST 3, not the two the comment names. AC1/AC2/AC3/AC4/AC6 all verified with fresh evidence and ticked; the consistency gate is clean. Status → in-progress; T5 reopens.
- 2026-08-01: REVIEW-PROCESS ERROR, recorded so it is not repeated — mutation and removal scripts were run in the shared working tree while three fresh-context reviewers were concurrently reading it, and one lens reported a CRITICAL finding (the `units` list missing `"average"`) that was purely an artifact of sampling the tree mid-script. The tree was verified identical to `HEAD` afterwards. Reviewers are told to use ref-based git precisely because the tree is shared; the orchestrator must hold tree-mutating verification until the lenses have returned, or run it before spawning them.

- 2026-08-01: T5 redone after review return 1 — every ledger figure re-measured by a per-cell census of the final grid's reducer-side `conf.low` (scratchpad script, 25 compared cells): `pmax(0, .)` reds 13 cells post-M98 / 10 pre (eight boundary 30x5 + two npbootstrap + three SSA = 0), grid min finite `conf.low` −2.533756 (npbootstrap `average`); `pmax(-1, .)` reds 3 cells incl. the `-Inf` cell since `pmax(-1, -Inf)` is `-1` (F5); finite-below-−1 census suppliers two (seeded npbootstrap −2.533756, seed-free SSA = 0 `unit = 2` −2); non-finite sole supplier SSA = 0 `average`. F3's `unit = 5` slip fixed to `unit = 6`, and the both-sides abort at `unit = 6` verified by running it, not assumed. F11's stale ROADMAP row figures corrected in place, marked. Test file green; full verify suite re-run below.

- 2026-08-01: gate re-run after the T5 redo — `air format --check .` silent, `lintr::lint_package()` 0 lints, `devtools::test()` at `NOT_CRAN=true CI=true` exit 0 / zero failures, `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes. Status → review (return 1 addressed).

## Decisions

## Review

### Return 1 (2026-08-01) — AC5 fails; back to `in-progress`

**Evidence per criterion** (fresh, run against final `HEAD` `dd13a09`; AC2/AC3/AC4
legs re-run after T5 so no result predates the comment rewrite):

- **AC1 ✅** — SSA = 0 case reaches the numeric comparison on all three units,
  reducer and `icc()` bit-identical (`identical()` TRUE): `single` −0.5,
  `average` −Inf, `2` −2. Fixture `bh_degen_between()` makes no RNG call, so
  seed-free as required. No other grid cell is non-finite (measured, 25 cells).
- **AC2 ✅** — dropping every class-(a) supplier fails `seen_finite_below_neg1`
  at `:2239` **by name**; dropping the class-(b) supplier fails `seen_nonfinite`
  at `:2240`. The named-assertion failure satisfies the confounding caveat.
- **AC3 ✅** — non-finite-only clamp at `R/icc.R:2209`: 0 failed pre-M98, 1
  failed post. `pmax(-1, x)` 1 → 3; `pmax(0, x)` 10 → 13. Tree restored and
  verified clean after each.
- **AC4 ✅** — literals are `26L`/`25L`, independently recomputed as
  8+8+4+1+2+3 = 26 checked, 25 compared. Dropping one unit fails the counts
  **alone**, both class assertions still passing.
- **AC5 ❌ FAILS** — see F4 below. The comment's `pmax(0, .)` ledger line is
  factually wrong, so the criterion's truthfulness requirement is unmet.
- **AC6 ✅** — `air format --check` silent; `lintr::lint_package()` clean;
  `devtools::test()` at `NOT_CRAN=true CI=true` FAIL 0 / PASS 5427;
  `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings /
  0 notes.

**Consistency gate:** `cairn_validate` exit 0, all checks pass (one standing
advisory, pre-migration dangling ids). `devtools::document()` no diff.
`pkgdown::check_pkgdown()` no problems. NEWS correctly absent — the diff is
test-only with no user-visible change.

**Independent review — three lenses, then a scorer.** Prior-PR-comments lens:
zero findings (checked M93's full pre-archive review via `git show` and M97's
archive against the diff; the `pulls/comments` probe returned `[]`, so the
thread walk was correctly skipped). Blame-history lens: 1 finding, 5 clean
confirmations. Diff-bug lens: 11 findings.

**ACTIONED (scored ≥ 80):**

- **F4 (82) — the `pmax(0, .)` ledger line undercounts its suppliers and the
  figure was carried over rather than measured.**
  `test-boundary-abort-hint.R:2088` reads "eight boundary cells, min -0.5855".
  Measured: 13 cells detect that mutation post-M98 (10 pre-M98), and the true
  minimum `conf.low` is −2.533756, not −0.5855 (which is only the minimum among
  the `searle`/`burch` cells). The figure was lifted from the ROADMAP candidate
  row, which contradicts T5's own work-log claim that "every figure in it is
  measured, none carried over from the plan". → **fix now**, via return to
  `in-progress`; it is an AC5 failure, not a review-side patch.

**LOGGED (scored < 80, surfaced not dropped — 11 findings):**

- F5 (78) — the `pmax(-1, .)` line names two suppliers, but `pmax(-1, -Inf)`
  is `-1`, so the SSA = 0 `average` cell reds it too: three, matching T3's
  measured POST 3. Independently confirmed at review. Should be fixed with F4.
- F3 (68) — the comment says `unit = 5` is excluded, but the unit the case
  declines to inherit from the shared list is `6`. Both refuse, so the
  substance holds; the sentence names a unit the list never held.
- F8 (68) — the new case requires three live glmmTMB fits on an exactly
  degenerate design to COMPLETE, unlike every other `bh_degen_between()` route
  in this file, which is error-tolerant by design. The file's own comment at
  `:2014-2017` records this failure mode (raw unclassed error on Linux/Windows,
  green locally). All gate evidence is local macOS. **Must be confirmed on CI.**
- F11 (50) — `cairn/ROADMAP.md:26` still says "sole supplier" and "eight
  boundary cells", both stale after this milestone.
- F1 (35) — `seen_nonfinite` uses `!is.finite()`, admitting NaN; `burch`
  returns NaN on this fixture but never runs on this case today.
- F6 (30) — "−Inf is IN support … `(-Inf, 1)`" is imprecise (open at the left);
  inherited verbatim from `R/ci-npbootstrap.R:126-128`.
- F7 (25) — the "not out of support" fence sits near a correct pre-existing
  "OUT of support" comment at `:2422`; scorer judged them different objects.
- F2 (20) — class flags read the reducer side; reportedness is pinned
  transitively by the `tolerance = 0` equality.
- F9 (15) — the cell pins `[-Inf, -Inf]` as a reported interval that
  `boundary_method_usable()` calls unusable; pre-existing shipped behavior,
  explicitly out of this milestone's scope.
- F10 (3) — milestone file dirty at review; committed as `c528483`.
- B1 (3) — a reviewer saw the `units` list mid-mutation. **Review-process
  error, not a code defect:** removal/mutation scripts were run in the shared
  working tree while three fresh-context reviewers were reading it. Tree
  verified identical to `HEAD` afterwards.

**Returns so far: 1.**

### Pass 2 (2026-08-01) — evidence at HEAD `563af84`

All removal and mutation legs re-run fresh at the final HEAD, **before** any
reviewer was spawned (the return-1 process lesson), tree verified clean after
each:

- **AC1 ✅** — per-cell census re-run this session against the final grid: 25
  compared cells, SSA = 0 case reaches the numeric comparison on all three
  units (`single` −0.5, `average` −Inf, `2` −2), the `average` cell the sole
  non-finite; `bh_degen_between()` makes no RNG call.
- **AC2 ✅** — dropping BOTH finite-below-−1 suppliers fails
  `seen_finite_below_neg1` **by name** (FAIL 3, with the two count literals);
  dropping the sole non-finite supplier fails `seen_nonfinite` by name
  (FAIL 3).
- **AC3 ✅** — non-finite-only clamp at the `conf.low` assembly: PRE (acd5610
  grid) FAIL 0 → POST FAIL 1. `pmax(-1, .)`: PRE 1 → POST 3. `pmax(0, .)`:
  PRE 10 → POST 13 (re-run with `testthat.progress.max_fails` raised — the
  default cap of 10 terminates the run at exactly the PRE count, so the first
  background run was censored at 10; the raised-cap run is the measurement).
- **AC4 ✅** — dropping one non-supplier unit (SSA `single`) fails the two
  count literals ALONE (FAIL 2), both class assertions still passing.
- **AC5 ✅** — every ledger figure verified against this pass's own
  measurements: 13 post / 10 pre `pmax(0, .)` detectors, grid min finite
  `conf.low` −2.533756, three `pmax(-1, .)` detectors incl. the `-Inf` cell,
  two finite-below-−1 census suppliers (one seeded, one seed-free), sole
  non-finite supplier; the `unit = 6` both-sides abort stated by the fixed F3
  sentence verified by running it. F4, F5, F3, F11 all confirmed fixed.
- **AC6 ✅** — `air format --check` silent; `lintr::lint_package()` 0 lints;
  `devtools::test()` at `NOT_CRAN=true CI=true` exit 0, zero failures;
  `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings /
  0 notes.

**Consistency gate (pass 2):** `cairn_validate` all 16 checks PASS (standing
pre-migration dangling-id advisory only); `devtools::document()` no diff;
`pkgdown::check_pkgdown()` no problems; NEWS correctly absent (test-only
diff); no new top-level files.

**CI:** PR #106 fully green at `563af84` — including `ubuntu-latest (release)`
and `windows-latest (release)` — whose test-file content is identical to the
final HEAD (the later commits are tracking-only). This is the confirmation
F8 required: the SSA = 0 case's three glmmTMB fits complete on Linux and
Windows.

**Independent review (pass 2) — three lenses, then a scorer.** All
tree-mutating verification ran and the tree was verified clean BEFORE the
lenses were spawned (the return-1 process lesson). Prior-PR-comments lens: no
regressions — the return-1 fixes (F3/F4/F5/F11) confirmed present in the diff
itself, the `pulls/comments` probe again returned `[]`. Blame-history lens: no
contradiction with recorded decisions or prior deliberate work; 7 areas
checked clean. Diff-bug lens: 13 candidate findings. Scorer verdict:
**no finding reached the 80 action threshold** — actioned list empty.

**LOGGED (all sub-80, surfaced not dropped — 15 scored):**

- DB5 (62) — AC5's "low-side detection was unasserted" element is stated only
  via the assertions being new-in-M98 (the "(M98)" tags and the
  assertions-exist-because paragraph), not in an explicit sentence about the
  low side; judged conveyed in substance, surfaced verbatim at the gate.
- DB11 (58) — the ROADMAP hygiene stamp ("nothing in flight") is falsified by
  M98 moving to `review` in the same diff; the stamp is replaced at post-merge
  hygiene, which resolves it.
- DB12 (48) — the ledger's "13 cells" is re-measurable only with
  `testthat.progress.max_fails` raised (default 10 censors the run); identity
  cells↔failures real but undocumented.
- DB10 (42) — the `unit = 6` exclusion sentence attributes the exclusion to
  the count literal rather than the one-deliberate-refusal invariant.
- DB4 (35) — ledger block physically attached to the pole-cell entry; "the
  pole cell above" refers to the prose paragraph, which is above.
- DB6 (33) — `!is.finite()` admits NaN/NA (F1 carried, 35 at return 1).
- DB2 (32) — "-Inf IN support of (-Inf, 1)" open-interval imprecision (F6
  carried, inherited phrasing).
- DB3 (22) — in/out-of-support comments describe different estimand objects
  (F7/F9 carried).
- DB1 (18) — T1's plan text still says `unit = 5`; plan-owned task prose,
  historical record of what the plan believed.
- DB7 (18) — census flags read the reducer side; deliberate, pinned
  transitively (F2 carried, 20).
- DB8 (15) / BH1 (15) / PR1 (15) — the F8 CI-fragility trio, resolved by the
  verified green ubuntu/windows runs above.
- DB9 (15) — stale line pointers in milestone task prose.
- DB13 (12) — single-fixture dependency observation, no incorrectness claimed.
