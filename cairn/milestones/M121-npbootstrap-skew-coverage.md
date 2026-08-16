# M121: Measure the `npbootstrap` interval's coverage on the frozen skew grid

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6
- **Branch/PR:** —

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
- [ ] AC2 — Before any grid cell is read, the harness reproduces the
      ukoumunne2003 Table I anchors U10/U30/U50 that
      `data-raw/m75-npbootstrap-coverage.R` validates the shipped reducer
      against, agreeing with the committed
      `tests/testthat/fixtures/npbootstrap-coverage-oracle.rds` coverage at each
      anchor within 2 binomial standard errors at that cell's `n_rep`, and
      aborts classed without writing output if any anchor misses.
- [ ] AC3 — The harness regenerates every replicate of the M111 grid from its
      recorded seed scheme and recomputes the `searle` and `burch` legs: the
      compared-row count is asserted equal to 64 × 2000 × 2 = 128,000, every
      compared endpoint matches `data-raw/m111-fallback-results.rds` within
      1e-12, and the harness refuses to run when the platform differs from that
      fixture's recorded `meta$platform`. A planted endpoint drift is shown to
      abort the run.
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

- [ ] T1 — Author `cairn/references/npbootstrap-skew-response-comparison.md`
      (rule N1 with its column named, tag vocabulary, known priors) and commit it
      alone, before any harness code exists.
- [ ] T2 — `data-raw/m121-npbootstrap-skew-sweep.R`: seed reconstruction from
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

## Decisions

## Review
