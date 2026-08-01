# M96: Failure accounting in the three MPL coverage-sweep generators

- **Status:** review
- **Branch:** m96-mpl-sweep-failure-accounting
- **PR:** https://github.com/jmgirard/intraclass/pull/103
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP7

## Goal

Make a failed `mpl_interval()` fit abort an MPL coverage sweep instead of being scored
as a covered replication.

## Scope

**In:** the covering-sentinel error handler
`error = function(e) c(lower = 0, upper = 1, rho_hat = NA_real_)` at
`data-raw/m90-mpl-coverage-sweep.R:89`, `m91-mpl-interp-sweep.R:125` and
`m92-mpl-095-interp-sweep.R:212` — after which `covered <- (lo <= rho) & (rho <= up)`
is TRUE for any ρ — replaced by one shared counted-failure path in
`data-raw/m86-mpl-lib.R` (all three already `source()` it); a per-cell failure count
plus a pre-write `stopifnot`; fault-injection evidence that the guard fires; and the
retrospective audit establishing the committed fixtures are unaffected.

**Out:** re-running any sweep — fixtures frozen at the plan gate (2026-07-25) under the
M91 ruling that shipped numbers stay the ones the recorded run measured; AC1's audit is
what establishes they are unaffected · the `uniroot` boundary/failure conflation in
`R/ci-mpl.R:178-188` and `data-raw/m86-mpl-lib.R:148-155`, which changes SHIPPED
behavior → candidate row added by this plan · CI wiring — `check-references` is
deliberately R-free (`.github/workflows/lint.yaml:42`) and the sweeps are multi-hour
offline jobs, so the guard is in-generator · the non-MPL `data-raw/` harnesses, which
return `NA`/`NULL`/`FALSE` and were checked this plan not to carry this defect · any
change to a committed coverage figure · the whole-table κ_m pin → M95.

## Acceptance criteria

- [x] AC1: the retrospective audit ships as committed evidence — a scan of the raw
      per-rep endpoints in `m90-coverage-sweep.rds`, `m91-interp-sweep.rds`,
      `m92-interp-sweep.rds` and `m92-interp-sweep-run1-collided.rds` for the
      `lower <= 0 & upper >= 1` sentinel, reporting a count per fixture. A non-zero
      count anywhere invalidates the frozen-fixtures decision and stops for a gate
      amendment rather than being absorbed.
- [x] AC2: all three generators route a failed `mpl_interval()` through one shared
      helper in `data-raw/m86-mpl-lib.R` that RECORDS the failure; no generator retains
      a literal `c(lower = 0, upper = 1)` error handler.
- [x] AC3 (GP5): each generator carries a per-cell failure count in its summary row and
      a `stopifnot()` that the total across cells is zero, placed BEFORE the fixture is
      written — a run with any failure produces no fixture at all, rather than a
      fixture carrying a footnote a later reader must notice.
- [x] AC4: the guard is mutation-verified, never argued — a fault-injection mode makes
      `mpl_interval()` fail on a chosen replication, and each of the three generators,
      run in its existing smoke mode under that injection, aborts with the failing cell
      named. Shipped as a `--self-test`-style flag mirroring
      `data-raw/check-reference-observations.py --self-test`, or a committed by-hand
      record if no flag fits. No comment claims more guarding than this establishes
      (M92 P6-1).
- [x] AC5: the change is accounting-only — each generator run in smoke mode WITHOUT
      injection completes and yields per-cell coverage equal to the pre-change code on
      the same seeds, so no measured number moves.
- [x] AC6: `lintr::lint_package()` (it lints `data-raw/` and rejects UPPERCASE
      constants, M62) and `air format --check` clean; `devtools::test()` and
      `devtools::check()` clean; `python3 data-raw/check-reference-observations.py` and
      `python3 data-raw/enumerate-generalizing-claims.py --check` green.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2
- AC4 → T3
- AC5 → T4
- AC6 → T5

## Tasks

- [x] T1: Commit the retrospective audit script and record its per-fixture sentinel
      counts in the work log. Any non-zero count stops for a gate amendment before the
      rest of the milestone proceeds.
- [x] T2: Add the shared counted-failure helper to `data-raw/m86-mpl-lib.R`; route all
      three generators through it; add the per-cell failure count to each summary row
      and the pre-write `stopifnot`.
- [x] T3: Add the fault-injection mode; run each generator in smoke mode under it and
      confirm each aborts naming the failing cell. Record per generator.
- [x] T4: Run each generator in smoke mode without injection and show per-cell coverage
      equals the pre-change code on the same seeds; record the comparison.
- [x] T5: Gate — `air format --check`, `lintr::lint_package()`, `devtools::test()`,
      `devtools::check()`, both references checkers; open the PR.

## Work log

- 2026-07-25: created by /milestone-plan (promotes M92 review finding F6; plan gate froze the existing fixtures — the audit run during planning found 0 sentinel reps across all four fixtures, 36000 reps — and sent the shipped `uniroot` clamp to a candidate row rather than folding it in).
- 2026-07-31: T1 done — `data-raw/m96-sentinel-audit.R` committed; run clean: m90-coverage-sweep 0/24000, m91-interp-sweep 0/6000, m92-interp-sweep 0/3000, m92-interp-sweep-run1-collided 0/3000 (0 sentinel hits / 36000 reps; exit 0). Frozen-fixtures decision stands.
- 2026-07-31: T2 done — `mpl_failure_log()`/`mpl_interval_counted()`/`mpl_cell_failures()`/`mpl_assert_no_failures()` added to `data-raw/m86-mpl-lib.R`; all three generators routed through them (no literal covering-sentinel handler remains, grep-verified); per-cell `failures` column in every summary row; assert after each cell's rep loop + pre-final-write `stopifnot(sum(failures) == 0L)`; on failure any on-disk checkpoint is removed so no fixture survives. The MPL_INJECT_FAILURE env-var hook (T3's mode) lives in the same helper, mirroring the generators' existing M90_SMOKE env-var idiom.
- 2026-07-31: T3 done — each generator run in smoke mode in a scratchpad sandbox under injection: m90 (`MPL_INJECT_FAILURE=0.99:C1:5`), m91 (`D2:10`), m92 (`E3:7`). All three: exit 1, abort message names the injected cell and rep ("cell 0.99:C1 rep 5: injected failure" etc.), and no fixture file on disk afterward — the m91/m92 targets sat mid-run, so earlier cells' checkpoints were written and then removed, exercising the no-fixture-survives path. Env-var mode chosen over a `--self-test` flag as the generators' existing idiom (AC4's "or" clause).
- 2026-07-31: T4 done — pre-change (commit c7796d5's tree) and post-change smoke runs of all three generators in sandbox copies, same seeds, no injection: raw per-rep endpoints `identical()` per fixture, all shared summary columns `identical()`, the only difference the new `failures` column (all zero). Accounting-only confirmed (AC5); committed fixtures untouched (sandbox runs, `git status` clean).
- 2026-07-31: T5 gate — `air format --check` clean; `lintr::lint_package()` 0 lints; `devtools::test()` FAIL 0 / PASS 5373 (3 pre-existing warnings in untouched test files); `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes; `check-reference-observations.py` 0 falsified; `enumerate-generalizing-claims.py --check` green. No NEWS entry: `data-raw/`-only, no user-visible change. Status → review; PR opened.

## Decisions

## Review

Fresh evidence, 2026-07-31, all by command on the branch tip:

- AC1: `Rscript data-raw/m96-sentinel-audit.R` re-run at review — 0 sentinel reps in
  all four fixtures (24000 + 6000 + 3000 + 3000 = 36000 reps), exit 0. Frozen-fixtures
  decision confirmed unaffected.
- AC2: grep at review — no `error = function(e) c(lower` handler in any generator
  (grep exit 1); exactly one `mpl_interval_counted(` call site per generator; all four
  helpers defined once in `data-raw/m86-mpl-lib.R` (lines 259/278/301/309).
- AC3: per generator, verified by line listing — `failures = mpl_cell_failures(...)`
  in the summary row, `mpl_assert_no_failures(fail_log, out_path)` after each cell's
  rep loop AND before the final write, plus `stopifnot(sum(summary_df$failures) == 0L)`
  before the final `saveRDS`. A failing run removes any on-disk checkpoint, so no
  fixture survives.
- AC4: injections re-run at review with NEW target cells (independent of implement's):
  m90 `0.90:C2:3`, m91 `D1:2`, m92 `E2:4` — each exits 1, prints "cell <id> rep <n>:
  injected failure", and leaves no fixture on disk. Env-var mode (`MPL_INJECT_FAILURE`)
  is AC4's "or" alternative to a `--self-test` flag, matching the generators' existing
  `M90_SMOKE` idiom.
- AC5: post-change smoke runs re-executed at review in a sandbox and compared to the
  committed pre-change baselines on the same seeds: raw per-rep endpoints `identical()`
  for all three fixtures; all shared summary columns `identical()`; the only new column
  is `failures`, all zeros. Committed fixtures untouched (`git status` clean).
- AC6: this session, by command — `air format --check` clean; `lintr::lint_package()`
  0 lints; `devtools::test()` FAIL 0 / WARN 3 (pre-existing, untouched files) /
  PASS 5373; `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings /
  0 notes; `check-reference-observations.py` exit 0 (0 falsified);
  `enumerate-generalizing-claims.py --check` exit 0.
- Driving RR: none — projection-vs-outcome no-ops.

Consistency gate (2026-07-31): `cairn_validate` exit 0 (321 pre-existing dangling-id
advisories, WARN only); no principle changed → `cairn_impact` skipped; `document()`
no diff; `pkgdown::check_pkgdown()` clean; README untouched by branch; NEWS not owed
(no user-visible change); `devtools::check()` 0/0/0 (AC6 run, same tree).

Independent review (three fresh-context lenses + scorer, 2026-07-31): diff-bug [O]
18 items, blame-history [S] 2, prior-review [S] 0 (archives searched M86–M95; GitHub
probe found no real threads — the diff is the fix for M92 F6, not a regression).
Scored 17 distinct findings; 1 actioned (≥80), 16 logged sub-threshold:

- **ACTIONED — D2 (83), fixed on the branch:** the fault-injection recipe documented
  in the `m86-mpl-lib.R` header, followed verbatim from the repo root, either deletes
  a committed fixture (guard fires) or overwrites it with smoke data (injection
  misses) — the sandbox discipline the M96 evidence runs used lived only in the work
  log. Fix: the header now prescribes running injection/smoke against a disposable
  copy, never the real `data-raw/` tree, and names the hazard (comment-only change).
- Sub-threshold, logged (score — one line): B1 (78) `file.remove` targets the
  committed fixture path — substance addressed by the D2 comment fix; deletion is
  git-recoverable. D1 (68) same root, local-CI consequence. D3 (55) unmatched
  injection spec is a silent no-op. D5 (55) checkpoint deletion loses multi-hour
  partial results and diagnostics — alternate design, AC3 mandates no-fixture.
  D4 (45) failing cell printed to stdout, abort message on stderr. D6 (35) failures
  column structurally always zero in any written fixture — AC3 asked for it. D9 (35)
  audit not NA-safe (cannot trigger on the frozen fixtures). D14 (35) no guard
  against a stale MPL_INJECT_FAILURE in a production shell. B2 (25) cumulative vs
  cell-scoped assert — behaviorally equivalent today. D10 (25) audit not wired into
  CI — one-off retrospective by design. D12 (25) sprintf %d on a double rep_i,
  latent. D7 (20) final pre-write assert redundant with per-cell assert — deliberate
  defense-in-depth per AC3. D13 (20) catches error only, class dropped — pre-existing
  shape. D11 (15) audit's exact 0/1 signature vs the generators' eps thresholds —
  documented as an upper bound on purpose. D15 (15) empty-summ degenerate guard,
  unreachable. D16 (10) `log`/`rep` shadow base names, no live conflict. D8 (5)
  `mpl_interval()`'s internal uniroot clamp — explicitly Scope OUT, the recorded
  ROADMAP candidate.
