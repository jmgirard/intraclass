# M121: Measure the `npbootstrap` interval's coverage on the frozen skew grid

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6
- **Branch/PR:** `m121-npbootstrap-skew-coverage`

## Goal

Measure `ci_method = "npbootstrap"` per-cell coverage on the 64-cell one-way
skew grid the M111 fixture holds, and record its disposition against a
pre-registered floor, so the repo can say for a fourth interval method what
D-027 established for three.

## Scope

**Surface tier: internal.** The deliverables are a `data-raw/` sweep harness, a
committed text fixture, a `references/` page and tracking records; no external
consumer relies on them. Any user-facing wording that follows from the verdict
is a separate milestone, the M113 → M115 shape.

**In:** a frozen rules page carrying rule N1 and its tag vocabulary; a harness
that regenerates the M111 replicates from their recorded seeds and adds an
`npbootstrap` leg; the committed per-cell coverage table; the verdict as a
D-entry.

**Out:**
- Any change to `?icc`, the vignettes, NEWS, or a runtime message → a follow-on
  milestone once the verdict exists (M113 → M115).
- `ci_method = "bootstrap"` on this grid → candidate row: measured at 10.6–15.0 s
  per call here, ~114 h at 4 workers for the full grid.
- `ci_method = "posterior"` and `"mpl"` → candidate rows; both refuse a one-way
  design by their own fences, not by cost (`intraclass_unsupported`).
- Any change to the default method → D-001 fenced, never traded here.

## Acceptance criteria

- [ ] AC1 — `cairn/references/npbootstrap-skew-response-comparison.md` carries
      rule N1, naming `coverage_uncond` as the column N1 reads, plus its tag
      vocabulary; and the commit adding that frozen-rules content is a *strict*
      ancestor of both the commit adding `data-raw/m121-npbootstrap-skew-sweep.R`
      and the commit adding `data-raw/m121-npbootstrap-skew-coverage.tsv` — for
      each pair `git merge-base --is-ancestor` exits 0 *and* the two SHAs differ.
      Checked at the review gate before the squash-merge, output recorded in
      `## Review`.
- [ ] AC2 — Before any grid cell is read, the harness re-runs the `npbootstrap`
      reducer at the two per-rep seed streams
      `data-raw/m75-npbootstrap-coverage.R:82,88` uses for the ukoumunne2003
      Table I anchors U10/U30/U50 (data `base + r`, resamples
      `base + 3000000L + r`, with `base` 5e7 / 6e7 / 7e7), pinning
      `n_rep = 2000` and `boot_samples = 999`, and requires each reproduced
      `coverage_icc1` to fall within the ±0.03 that
      `tests/testthat/test-ci-npbootstrap-coverage.R:31` pre-registers against
      the Table I figures 0.938 / 0.944 / 0.9395 (ukoumunne2003 Table I,
      k = 10 / 30 / 50, n = 10 ratings, rho = 0.05). It aborts
      `intraclass_*`-classed without writing output if any anchor misses, and a
      planted perturbation of the reducer's resample stream is shown to fire
      that abort. Its difference from the committed
      `tests/testthat/fixtures/npbootstrap-coverage-oracle.rds` value is
      recorded beside the run as a delta, never a failure (D-024 clause 2).
- [ ] AC3 — The harness regenerates every replicate of the M111 grid from its
      recorded seed scheme and recomputes the `searle` and `burch` legs: the
      compared-row count is asserted equal to 64 cells × 2000 reps × 2 legs =
      256,000 and the compared-endpoint count to twice that, 512,000; every
      compared endpoint matches `data-raw/m111-fallback-results.rds` within
      1e-12; and the harness compares each field the fixture records under
      `meta$platform` (`r_version`, `sysname`, `machine`) against the current
      session, aborting and naming every differing field — platform axes the
      fixture does not record (BLAS, compiler, TMB linkage) are outside that
      gate and are not claimed. A self-test plants, one at a time, a drift on
      each of the four (leg, endpoint) combinations of `{searle, burch} ×
      {lower, upper}`, including one at 5e-12 just above the tolerance, and
      requires each to abort naming its own planted row; a 5e-13 plant below the
      tolerance is required *not* to abort; a truncated cell is required to fire
      the row-count assertion; and a perturbation of each recorded
      `meta$platform` field in turn, plus a `NULL` platform, is required to fire
      the platform gate. Its control — a reduced 20-rep instance of the grid's
      first cell, its own compared count asserted at 40 — reproduces cleanly
      under no plant.
- [ ] AC4 — `data-raw/m121-npbootstrap-skew-coverage.tsv` is committed with one
      row per (cell, method) over the 64 cells and the four legs
      `npbootstrap`/`mc`/`searle`/`burch`, carrying the column set of
      `data-raw/m113-skew-response-coverage.tsv`; the `npbootstrap` leg's
      `n_abort` counts replicates where `icc()` signalled a classed
      `intraclass_*` condition, read from the condition class and never from
      endpoint finiteness; a non-finite `npbootstrap` endpoint arriving without
      such a condition raises rather than being counted.
- [ ] AC5 — A `cairn/DECISIONS.md` entry records the N1 disposition for
      `npbootstrap`: the count of the 64 cells below the frozen 0.93
      `coverage_uncond` floor and the worst cell's coverage with its
      (rho, k, n, dist); the failing cells partitioned by abort rate at D-027's
      0.1 boundary with `coverage_nonabort` reported for each part; and whether
      D-027's S1 reopening condition is met. The entry names no bracketed claim
      token.
- [ ] AC6 — `cairn/references/INDEX.md` carries the new page's line; the
      harness's checkpoint site is registered in `data-raw/checkpoint-sites.tsv`;
      and `enumerate-generalizing-claims.py --check`,
      `check-reference-observations.py`, `check-mpl-doc-claims.py`,
      `check-record-claims.py` and `check-checkpoint-sites.R` each exit 0.
- [ ] AC7 — `Rscript -e 'devtools::test()'` reports 0 failures and 0 errors; the
      glmmTMB/TMB build-version mismatch is the only warning tolerated at load,
      and is named in the evidence if present.

## Coverage

- AC1 → T1
- AC2 → T3
- AC3 → T2
- AC4 → T4, T5
- AC5 → T6
- AC6 → T4, T7
- AC7 → T7

## Tasks

- [x] T1 — Author `cairn/references/npbootstrap-skew-response-comparison.md`
      (rule N1 with its column named, tag vocabulary, known priors) and commit it
      alone, before any harness code exists.
- [x] T2 — `data-raw/m121-npbootstrap-skew-sweep.R`: seed reconstruction from
      M111's scheme (`base_seed = cell$id * 1000000L`,
      `data-raw/m111-fallback-sweep.R:294`), the `meta$platform` gate, the
      searle/burch identity check at 1e-12 with the 128,000-row count assertion,
      and a self-test that plants an endpoint drift and requires the abort.
- [ ] T3 — Add the ukoumunne2003 U10/U30/U50 anchor precondition, run before any
      grid cell and aborting classed on a miss.
- [ ] T4 — Add the `npbootstrap` leg: classed-condition abort accounting, raise
      on non-finite-without-condition, per-cell checkpointing, and the site's row
      in `data-raw/checkpoint-sites.tsv`.
- [ ] T5 — Run the sweep in the background (check for concurrent R sessions and
      live R.INSTALL processes first — M107/M109) and write
      `data-raw/m121-npbootstrap-skew-coverage.tsv`.
- [ ] T6 — Fill the page's Results and Disposition sections; write the D-entry
      with the floor count, the worst cell and the abort-rate split.
- [ ] T7 — Records hygiene: INDEX line, triage rows for the page's generalizing
      claims, all five checkers, `devtools::test()`.

## Work log

- 2026-08-15: created by /milestone-plan.
- 2026-08-15: plan-gate measurement — on a one-way design `mpl` and `posterior` both abort `intraclass_unsupported` (design fence / brms-engine requirement), and `bootstrap` costs 10.6–15.0 s per call against `npbootstrap`'s 0.16–0.21 s.
- 2026-08-15: criteria audit ([O], fresh context) returned 14 findings; 9 fixed into the criteria before writing (same-commit ancestor hole, freeze clause vs the page's own post-derivation fill, unbounded "every derivation artifact", vacuous compare-count, non-finite-without-condition gap, N1's unnamed coverage column, omitted `check-checkpoint-sites.R`, undefined "runs clean", and a missing oracle anchor for the new leg), 3 raised at the gate.
- 2026-08-15: plan gate chose `npbootstrap` alone over also sweeping `bootstrap` because the full grid costs ~114 h at 4 workers against ~2–8 h; falsified by a measured per-call cost that brings the parametric grid under a working day.
- 2026-08-15: plan gate chose a 1e-12 tolerance plus the `meta$platform` gate over bit-exact `identical()` because exact equality is a property of the machine's summation order (M105) and the sole precedent used the tolerance form; falsified by a regenerated endpoint pair differing above 1e-12 on the recorded platform.
- 2026-08-15: plan gate chose to freeze the verdict on `coverage_uncond` while requiring the failing cells split by abort rate over judging on `coverage_nonabort` alone, because the unconditional column is what D-027 judged the other three legs on; falsified by a split showing every failing cell sits above D-027's 0.1 abort boundary, which would make the verdict a restatement of D-026's already-adjudicated selection effect.

- 2026-08-15: gated amendment — AC2 rewritten. Its plan-time bound ("2 binomial standard errors") was invented where the repo already pre-registers ±0.03 for these anchors (`test-ci-npbootstrap-coverage.R:31`), which is bar-setting against GP5. Fresh-context [O] audit of the redraft returned 10 findings, all actioned before writing: the two-leg form made the published-oracle leg vacuous (fixture sits 0.0005/0.0085/0.0030 from Table I against a proposed 0.005 slack); the replacement 0.005 was a tighter invented bound than the one it replaced; the resample-seed offset `base + 3000000L + r` was omitted, without which a conforming harness reds on a correct package; and making fixture drift terminal contradicts D-024 clause 2 ("a delta, never a failure"). Now: ±0.03 against Table I is the only operative gate, drift is recorded, the abort names its class and carries a probe.
- 2026-08-15: AC2's anchors are gaussian cells at rho = 0.05 while the swept grid is the skew grid, so a green AC2 is evidence about the reducer and never about the swept domain (GP6). Recorded here rather than in the criterion, which does not overclaim.
- 2026-08-15: rebuilt glmmTMB 1.1.14 from source against TMB 1.9.23, clearing the build-version mismatch that would otherwise have sat under T5's multi-hour sweep (M107/M109). Not a dependency change: CRAN's current glmmTMB is also 1.1.14, so the package set is unchanged and only the compiled linkage moved. Suite run before and after at `NOT_CRAN=true CI=true` is identical on both axes — `FAIL 0 | WARN 2 | SKIP 25 | PASS 7302` each time, and a per-test diff of the SKIP/WARNING lines is empty — so no pinned number moved. `library(glmmTMB)` now loads silently; AC7's tolerated-warning clause is consequently unexercised.
- 2026-08-15: T1 — frozen rules page committed alone, before any harness code. Gate chose to reuse D-027's S1 `replace-GO`/`no-GO` vocabulary over neutral floor labels, so D-027's reopening condition reads off the tag; falsified by a reader taking `replace-GO` as a default-method change, which the page and D-001 both fence.
- 2026-08-15: T1 known priors re-derived from the committed fixtures rather than recalled — `npbootstrap` on M76's 16-cell grid covers 0.9245–0.9495 with zero aborts (one cell under 0.93), and the three incumbents fail this grid's floor at 21/64, 16/64 and 49/64 (`coverage_uncond`).
- 2026-08-15: amendment return: AC3 — "the compared-row count is asserted equal to 64 cells × 2000 reps × 2 legs = 256,000 and the compared-endpoint count to twice that, 512,000" — the plan-time clause multiplied out to 128,000, which is not the product; found by the assertion firing on the first full run.
- 2026-08-15: criteria audit ([O], fresh context) of the amended AC3 returned 8 findings, 7 actioned into the wording before writing (stale 128,000 renderings in the harness, the endpoint count left unasserted, the control's 20-rep truncation unstated, the platform promise wider than the three recorded fields, a single-exemplar plant that a 1e-6 tolerance would also pass, and the count and platform assertions never shown to bite). Not actioned: AC3 says "abort" where AC2 says classed — `data-raw/` harnesses use bare `stop()` by M111 precedent and the classed-error rule governs the package's user-facing layer.
- 2026-08-15: T2 — the M111 grid regenerates from its recorded seeds **bit-identically** on this platform: 256,000 rows / 512,000 endpoints, worst |delta| exactly 0, in 19 s at 4 workers. The 1e-12 tolerance is therefore slack the run never used.
- 2026-08-15: gate chose to run the ~16–21 min anchor validation on every harness invocation including checkpoint resumes, over validating once and stamping, because a stamp is a second record that goes stale; falsified by the validation's share of total sweep runtime rising above the ~5–10% measured here.

## Decisions

## Review
