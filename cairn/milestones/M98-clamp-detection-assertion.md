# M98: Assert the endpoint-parity test's clamp-detection classes, and add the non-finite one

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M93
- **Driving RR:** —
- **Principles touched:** GP5, GP7
- **Branch/PR:** `m98-clamp-detection-assertion`

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

- [ ] AC1 The AC4 grid reaches the numeric reducer-vs-`icc()` comparison
      (`tolerance = 0`) on at least one cell whose reported `conf.low` is
      **non-finite**, supplied by a **seed-free** fixture. No cell does at HEAD.
- [ ] AC2 The test asserts **per class** that a compared cell exists with (a) a
      finite `conf.low` strictly below −1 and (b) a non-finite `conf.low`. Each
      assertion reds when its own class is removed from the grid — established
      by removal, not by inspection, and recording that the **class assertion
      itself** failed, since removing a cell also reds the count literals.
- [ ] AC3 Mutation evidence at the reporting-path assembly (`R/icc.R:2209`),
      recorded from real runs: a clamp binding **only** on non-finite endpoints
      passes at HEAD and reds after this milestone; `pmax(-1, .)` and
      `pmax(0, .)` red both before and after. The first leg is the one that
      establishes the new cell adds detection rather than duplicating it.
- [ ] AC4 The `checked` / `compared` exact-count assertions are updated as
      integer literals — never expressions derived from `cases`, which would
      self-adjust and assert nothing — and still red on a silently dropped
      cell, verified by removing one unit from the new case.
- [ ] AC5 The comment heading these cells states truthfully which clamp classes
      the grid detects and which cells supply each — naming the npbootstrap
      `unit = "average"` cell as the **sole** supplier of the finite-below-−1
      class and that it is **seeded** (`seed = 4`); that low-side detection
      predates this milestone and was unasserted; and that high-side detection
      is unreachable through any shipped `ci_method`. Endpoints below −1 or
      non-finite are **not** called "out of support" — under D-010 the
      projected form's support is `(-Inf, 1)`, so the honest phrase is outside
      the conventional `[-1, 1]` range.
- [ ] AC6 The PROFILE `verify` slot is clean — `devtools::test()` at
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
- [ ] T4 Removal checks: drop each class's supplying cell in turn and confirm
      the matching assertion reds; drop one unit and confirm the count
      assertion reds; restore.
- [ ] T5 Rewrite the comment block (`:2073-2087`) to the post-M98 state per AC5.
- [ ] T6 Gate: `air format .`, `lintr::lint_package()`, `devtools::test()` at
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

## Decisions

## Review
