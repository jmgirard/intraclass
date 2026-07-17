<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M59: Test-suite speed — rigor-invariant levers

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Principles touched:** GP5, GP6, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m59-test-suite-speed / https://github.com/jmgirard/intraclass/pull/63   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Cut testthat wall-clock via rigor-invariant levers — parallelism, right-sized
stochastic counts, deduped refits, skip-gating audit — without loosening any
oracle tolerance, coverage claim, or failure-axis sweep.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:**
- Enable `Config/testthat/parallel: true`; resolve any test-ordering / shared-
  state fallout it exposes.
- Right-size over-provisioned stochastic counts to their noise floors, each
  re-derived and kept `tol ≥ 3·√(2/df)/√n_rep` (GP5). Concrete targets:
  `test-icc-lavaan-multilevel.R` (`mc_samples=4000` @492; `n_rep_b=60` @218;
  `n_rep_d=40` @267; `mc_samples=500` @247/290), `test-ci-bootstrap.R`
  (`boot_samples=499` @100/242/252/518/557/568), `test-d-study.R`
  (`boot_samples=499/999` @641/671/710).
- Dedupe repeated model refits within the three fat files
  (`test-icc-lavaan-multilevel.R`, `test-ci-bootstrap.R`, `test-d-study.R`) via
  shared file-top / block-local fixtures.
- Audit `skip_on_cran` / `skip_on_ci` gating so the heaviest live-Stan brms and
  coverage sweeps run only where intended.
- Record a per-file before/after wall-clock table (baseline below).

**Out:**
- Freezing the live coverage/recovery sweeps (the `n_rep` lavaan-refit loops,
  d-study coverage sims) into committed `.rds` fixtures (lever b) → candidate
  "Freeze live coverage/recovery sweeps to fixtures" (rigor tradeoff per M51;
  needs its own per-pin argument).
- Any change lowering a stochastic count below its noise floor, dropping a
  failure-axis cell — the ragged coverage `n_rep≥240` (ADR-042 Amdt 2), the
  cluster-count sweep (M27/M28) — or weakening a guard's mutation-testability
  (GP6/GP7).
- Plotting polish → separate candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: `Config/testthat/parallel: true` set in `DESCRIPTION`; the full suite
      passes with identical-or-higher pass counts and zero new failures both
      locally under `NOT_CRAN=true` + live Stan and on CI. Evidence: pass-count
      diff vs the pre-milestone run.
- [x] AC2: A per-file before/after wall-clock table is committed to the work log,
      measured under a fixed condition (`NOT_CRAN=true CI=true`, live-Stan
      skipped, one reference machine) against the plan-time 415 s baseline
      below, showing a net reduction. Evidence: the table.
- [x] AC3: Every stochastic count that changed keeps `tol ≥ 3·√(2/df)/√n_rep`
      (GP5): a per-changed-pin table of (count old→new, df, floor, tol) with all
      affected tests passing. Evidence: the table + green tests.
- [x] AC4: No failure-axis cell dropped (GP6) — the ragged coverage `n_rep≥240`
      (ADR-042 Amdt 2) and the cluster-count sweep cells (M27/M28) are unchanged.
      Evidence: diff/grep showing those counts untouched.
- [x] AC5: Right-sized guards still discriminate (GP7): a spot mutation-check on
      ≥1 right-sized pin per fat file shows the guard goes red under a plausible
      wrong value / simplification (M51 patch-source → `load_all` → run → revert
      method). Evidence: mutation notes in review.
- [x] AC6: Skip gating audited (lever d): a documented gating matrix shows each
      heavy live-Stan / coverage block runs only where intended, with no heavy
      block silently running on CRAN nor silently skipped everywhere. Evidence:
      the matrix.
- [x] AC7: Active profile verify slot clean — `devtools::test()` clean; and
      because `DESCRIPTION` changes structurally, `devtools::check()` clean
      (0 errors/warnings; NOTEs justified).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T7
- AC2 → T1, T2, T3, T4
- AC3 → T3, T6
- AC4 → T3, T6
- AC5 → T6
- AC6 → T5
- AC7 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Record the plan-time baseline (the 415 s per-file table below) in the
      work log and commit a small reproducible profiling helper
      (`data-raw/profile-tests.R` or equivalent) so before/after is repeatable.
- [x] T2: Set `Config/testthat/parallel: true` in `DESCRIPTION`; run the full
      suite; fix any ordering / shared-state fallout (helper globals, missing
      `setup-*.R`). Re-measure.
- [x] T3: Right-size the over-provisioned counts listed in Scope. For each: re-
      derive the noise floor, cut the count to the smallest value keeping
      `tol ≥ floor` with margin, adjust `tol` per GP5 if needed. Never touch the
      ragged `n_rep≥240` or the cluster-count sweep.
      (RB tripwire: none — right-sizing under GP5, no new oracle.)
- [x] T4: Dedupe repeated refits in the three fat files — hoist shared pilot-
      geometry / base-model fits into file-top or block-local fixtures reused
      across blocks. Re-measure.
- [x] T5: Audit `skip_on_cran` / `skip_on_ci` gating across the heavy blocks;
      assemble the gating matrix (block → runs-on) for AC6.
- [x] T6: Assemble the GP5 noise-floor table (AC3) and the GP6 failure-axis-
      unchanged evidence (AC4); run the AC5 spot mutation-checks (≥1 per fat
      file).
- [x] T7: Full verify — `devtools::test()` clean + `devtools::check()` clean;
      confirm no NEWS entry is owed (test-only changes are not user-visible).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan. Promoted from the "Test-suite speed
  audit" candidate (added conversationally 2026-07-17). Plan-time baseline
  (full suite, `NOT_CRAN=true CI=true`, live-Stan skipped, ~415 s total):
  test-icc-lavaan-multilevel.R 126 s · test-ci-bootstrap.R 125 s ·
  test-d-study.R 90 s · test-icc-multilevel.R 25 s · all others ≤7.5 s.
  Cross-ref M57/M58 (lavaan multilevel siblings) — they add tests to the hottest
  file; those should follow this milestone's parallelism + right-sizing
  conventions once merged.
- 2026-07-17 (T1): committed `data-raw/profile-tests.R` (fixed condition
  `NOT_CRAN=true CI=true`, live-Stan skipped); baseline table above is its output.
- 2026-07-17 (T2): DESCRIPTION `parallel: true` + `start-first` (3 fat files).
  Parallel run FAIL 0 / PASS 1724 / SKIP 23, 233 s vs 415 s serial (−44%); no
  shared-state fallout; WARN 2 pre-existing. (details → Review)
- 2026-07-17 (T3): cut only STRUCTURAL `boot_samples` to B=99 (ci-bootstrap ×5,
  d-study ×4 + literals); left every O1/O2 oracle + all `mc_samples` (cheap
  draws) untouched. No oracle tol changed. (details → Review)
- 2026-07-17 (T4): memoized d-study `fit_ds` (deterministic seed=1); measurable
  Δ≈0 — fat-file cost is distinct random-rep sims (lever b), not duplication.
- 2026-07-17 (T5): skip-gating audit — no anomaly, matrix in Review.
- 2026-07-17 (T6): AC3 vacuous (no oracle tol changed), AC4 axis intact, AC5
  mutations both RED. (details → Review)
- 2026-07-17 (T7): `check(NOT_CRAN=false)` 0/0/0; `test()` FAIL 0 / PASS 1724;
  no NEWS owed. (measurements → Review)

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

**Reviewed 2026-07-17 (PR #63). Fresh evidence per criterion:**

- **AC1 ✓** — DESCRIPTION carries `Config/testthat/parallel: true` +
  `start-first`. Fresh heavy-path run (`NOT_CRAN=true CI=true`, parallel):
  FAIL 0, PASS 1724, SKIP 23 — pass count identical to the pre-milestone
  baseline; zero new failures. No shared-state fallout.
- **AC2 ✓** — per-file net reduction, isolated measurement (fixed condition,
  live-Stan skipped): ci-bootstrap 125→114 s, d-study 90→59 s (~42 s CPU work
  removed, load-independent); other files unchanged. Parallel wall-clock ran
  205–233 s uncontended vs the 415 s serial baseline (measurements taken under
  concurrent load — e.g. 451 s during the review's subagents — are contaminated
  and disregarded; testthat parallel wall-clock is inherently contention-noisy).
- **AC3 ✓** — `git diff main..HEAD -- tests/` changes ONLY `boot_samples` +
  their asserted `samples` literals; no `tolerance`, `mc_samples`, or `n_rep`
  line changed. Every changed count feeds a structural assertion, none a
  stochastic tolerance ⇒ no noise floor applies (vacuous by construction).
- **AC4 ✓** — the test-code diff contains no `n_rep` and no `240` line; ragged
  coverage `n_rep≥240` (ADR-042 Amdt 2) and the cluster-count sweep (M27/M28)
  are untouched.
- **AC5 ✓** — M51 mutation-checks re-run: ci-bootstrap (swap `two_sided_interval`
  endpoints, R/ci-montecarlo.R:100) → B=99 "well-formed" guard RED (2 fails);
  d-study (constant `resolve_divisor`, R/estimand.R:178) → B=99 "monotone" guard
  RED (1 fail). Both reverted clean. lavaan-ml had no right-sized pin.
- **AC6 ✓** — gating matrix documented (work log T5): live-Stan brms
  `skip_on_cran`+`skip_on_ci` (23/23, 0 leaks); heavy bootstrap/recovery sweeps
  `skip_on_cran`; light single-fit oracles run on CRAN. No heavy block on CRAN,
  nothing skipped everywhere.
- **AC7 ✓** — fresh `devtools::check(NOT_CRAN=false)`: 0 errors, 0 warnings, 0
  notes; `devtools::document()` no-diff; `devtools::test()` FAIL 0.

**Consistency gate:** `cairn_validate` PASS (all checks; 290 advisory
historical-citation warnings, not gate failures). `document()` no-diff. No
DESIGN.md principle changed (GP5/GP6/GP7 worked-under, not modified) ⇒
`cairn_impact` skipped. `check()` 0/0/0. No NEWS entry owed (test infra +
DESCRIPTION config only; no user-visible change). `data-raw/profile-tests.R`
covered by the existing `^data-raw$` `.Rbuildignore` entry.

**Independent three-lens review (fresh context, parallel):**
- [O] diff-bug (Opus): **0 findings** — all 9 reduced blocks assert B-invariant
  structural properties; every O1/O2 oracle count left untouched; 3 asserted
  `samples` literals match their reduced fits; `start-first` basenames resolve;
  `fit_ds` memoization read-only + per-worker safe; no R/ code changed.
- [S] blame-history (Sonnet): **0 findings** — each reduced count was introduced
  at its feature commit (M16/M18/M21) and never later raised to cure a flake;
  no ADR-042/M27/M28 resurrection; memoization contradicts no D-entry.
- [S] prior-PR-comments (Sonnet): **no prior-PR evidence** — repo has 0 human PR
  review comments across all 62 merged PRs; clean no-op, 0 findings.

Zero surviving findings across all three lenses ⇒ nothing passed to the scorer;
actioned list empty, below-80 list empty. Non-finding noted (not actioned):
`tests/testthat/_problems/` holds stale local testthat artifacts (gitignored +
`.Rbuildignore`d, not in the diff, not shipped).

**Diffstat (vs main):** DESCRIPTION +2, test-ci-bootstrap.R (14 lines),
test-d-study.R (44 lines), data-raw/profile-tests.R (new), cairn tracking. No
`R/` product code.
