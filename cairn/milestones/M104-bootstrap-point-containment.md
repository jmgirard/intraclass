<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M104: What the parametric bootstrap reports when its interval sits above its own point

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1, GP6, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m104-bootstrap-point-containment` / https://github.com/jmgirard/intraclass/pull/112   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Measure where `ci_method = "bootstrap"` reports a lower limit above its own point
estimate, commit that measurement, and make the package's boundary documentation
state the relation it actually holds.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a committed sweep script + fixture over two arms of the between-subject-
variance axis (GP6); the `"bootstrap"` documentation surface gaining a boundary
point/interval paragraph; the correction of one sentence at `R/icc.R:502` that
this milestone's own fixture falsifies; the `DESIGN.md` Bootstrap row; a live
regression test pinning the motivating call; NEWS.

**Out:** any change to a reported number — no clamping, no reconciliation of
point to interval → a ROADMAP candidate row, promoted only if a gap is ever
measured outside the bound AC2 pins. A containment condition in
`boundary_interval_usable()` → candidate row; adding one would silence M103's
hint on exactly the data M103 exists to serve. Bias-corrected variants (BCa) →
barred for `npbootstrap` by D-006 and not proposed here for `"bootstrap"`; a
separate scope if ever wanted. The other five reducers → candidate row (this
sweep covers `"bootstrap"`, the method the observation came from).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: `data-raw/sweep-bootstrap-point-containment.R` is committed and writes
      `tests/testthat/fixtures/bootstrap-point-containment.tsv`, one row per
      (arm, n_s, n_r, spread, seed, index) cell carrying the point estimate, both
      endpoints, `conf.low > estimate`, and a `status` column whose value records
      whether the cell returned or aborted — so a cell aborting at
      `R/ci-bootstrap.R:58` appears as a row rather than leaving the fixture. The
      grid contains >= 12 returned cells per arm, spanning a zero-between-subject-
      variance generator and a nonzero-between-subject-variance generator (GP6).
- [x] AC2: A test reading the committed fixture asserts, over exactly the
      `status == "ok"` rows that fixture contains and claiming nothing about cells
      outside it: every such row with `conf.low > estimate` has both
      `conf.low - estimate < 1e-8` and `estimate < 1e-8`; and every such row with
      `estimate >= 1e-8` has `conf.low <= estimate`.
- [x] AC3: The `"bootstrap"` documentation surface in `R/icc.R` (the parametric
      bootstrap, described from `R/icc.R:323`; NOT the `"npbootstrap"` section
      whose heading is `R/icc.R:467`) states that at the zero-between-variance
      boundary the reported interval may sit entirely above the reported point.
      The paragraph carries exactly two quantitative items and no others: the
      `1e-8` bound AC2 asserts, and the fixture path AC1 names.
- [x] AC4: The sentence at `R/icc.R:502` asserting that the point "reads `0`" at
      the zero-between-variance boundary is corrected in place to what the engine
      returns — a value at or numerically indistinguishable from zero — because
      the AC1 fixture records that point as nonzero, and its being nonzero is the
      mechanism AC3 documents. Corrected, not appended beside (D-045: roxygen is
      current knowledge).
- [x] AC5: The Bootstrap row of the interval-time boundary table in
      `cairn/DESIGN.md` (line 200 at plan time) states the point/interval relation
      AC3 documents, since `cairn/DESIGN.md` declares that section the single home
      for boundary policy.
- [x] AC6: A test calls `icc()` on the zero-between-variance dataset built by the
      generator at `tests/testthat/test-reducer-abort-hint.R:34` with
      `n_s = 6, n_r = 3, jitter_sd = 0, seed = 1`, passing
      `model = "oneway", ci_method = "bootstrap", seed = 1L, boot_samples = 999L`
      and the shipped defaults for `engine`, `unit` and `conf_level`, and asserts
      on the returned ICC(1) row that `conf.low > estimate` and that both are
      below `1e-8` — the motivating observation itself.
- [x] AC7: The `r-package` profile's `verify` slot is clean, plus
      `lintr::lint_package()` and `air format --check`.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Write `data-raw/sweep-bootstrap-point-containment.R` over both arms
      (zero-between-variance and nonzero-between-variance generators), run it, and
      commit the script with its fixture. Follow the committed-sweep idiom already
      used by `data-raw/sweep-abort-remedies.R` +
      `tests/testthat/fixtures/abort-remedy-sweep.tsv`. Lessons: `lintr` lints
      `data-raw/` and rejects UPPERCASE constants, so run `lint_package()` before
      pushing.
- [x] T2: Add the fixture-reading test asserting AC2's two closed-scope claims.
- [x] T3: Add the boundary point/interval paragraph to the `"bootstrap"` docs
      (`R/icc.R:323` onward) and correct the `R/icc.R:502` "reads `0`" sentence;
      `devtools::document()`.
- [x] T4: Update the Bootstrap row of the `cairn/DESIGN.md` interval-time boundary
      table.
- [x] T5: Add the live regression test pinning the AC6 call.
- [x] T6: NEWS entry; run the local gate (`document()` no delta,
      `air format --check`, `lintr::lint_package()`, tests against the installed
      package with `NOT_CRAN=true CI=true`).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-05: created by /milestone-plan, promoting the 2026-08-04 candidate row (lineage: M93 hint → M103 AC6).
- 2026-08-05: plan-gate measurement — 42 cells swept live before scoping; lower limit exceeds the point in 21 of 24 zero-between-variance cells (max gap 5.45e-10, every excluding cell's point ~1e-10) and in 0 of 18 nonzero-ICC cells.
- 2026-08-05: plan gate chose measure-and-document over reconciling the reported numbers and over warning the user, because the measured divergence lies inside the numerical-zero floor and the parametric bootstrap simulates from the fitted model, so a boundary fit yields boundary resamples; falsified by a measured gap outside the AC2 bound, or an excluding cell whose point estimate is materially nonzero.
- 2026-08-05: plan gate chose a `"bootstrap"`-only sweep over an all-six-reducer sweep, because the observation came from that reducer and the refit-per-resample cost dominates; falsified by the same shape being reported against another `ci_method`.
- 2026-08-05: criteria audit ran ([O], fresh context) and returned 8 findings, all actioned at the gate — AC3 was retargeted from the `"npbootstrap"` section to the `"bootstrap"` surface, AC4 added to correct a sentence the fixture falsifies, AC5 added for the DESIGN.md row, AC6 given a pinned generator and full argument list plus the ordering assertion nothing had pinned, AC1 given per-arm minimum cells and a status column, and two unenumerated universals removed.
- 2026-08-05: collision check — D-006's percentile/BCa NO-GO is scoped to the non-parametric `npbootstrap` reducer, not this parametric one, and nothing here adds a bias-corrected variant, so the scopes are recorded as distinct and cross-referenced rather than superseded.
- 2026-08-05: T3 done — the `@param ci_method` bootstrap description gains the boundary point/interval paragraph, and the `R/icc.R` npbootstrap-section sentence asserting the point "reads `0`" is corrected in place to "at, or numerically indistinguishable from, `0`"; `document()` clean.
- 2026-08-05: T4 done — the DESIGN.md interval-time Bootstrap row states the relation and cites the fixture path.
- 2026-08-05: implement gate chose to sweep at the shipped `boot_samples = 999` over the faster 199 the plan-gate probe used, so the fixture and AC6's live call measure the same experiment (the rule `data-raw/sweep-abort-remedies.R` already records); falsified by a cell whose containment verdict differs between the two counts.
- 2026-08-05: minor plan refinement — the fixture gains `boot_samples` and `conf_level` columns beyond AC1's named schema, so the recorded bound is scoped to the count it was measured at.

- 2026-08-05: T1/T2/T5 done — the sweep wrote 48 rows (48 ok, 0 aborted, 24 per arm); `conf.low > estimate` in 22, all 22 in the zero-between arm and none in the nonzero arm; largest gap 2.12e-09 and largest point estimate among them 2.90e-09, both inside the 1e-8 bound AC3 documents. All 17 rows with a point at or above 1e-8 contain their point. Tests green (9 assertions).
- 2026-08-05: the fixture's first row reproduces the candidate row's 2026-08-04 observation exactly (point 3.40890543108706e-10, conf.low 4.80452439535659e-10).

- 2026-08-05: T6 done — NEWS entry under Documentation; local gate clean: `air format --check` exit 0, `lintr::lint_package()` 0 lints, `devtools::document()` no delta, and the full suite against the INSTALLED package under `NOT_CRAN=true CI=true` with failed + error = 0 (23 skips, the live-Stan brms set plus skip_on_cran).
- 2026-08-05: all tasks done; status -> review.

- 2026-08-05: review found CI red on `check-references` — `data-raw/check-mpl-doc-claims.py` rejected AC3's two new sentences as generalizing claims with no ledger row. Fixed on the branch: both registered `out` (that ledger settles against the M92 MPL interpolation fixture, which cannot speak to a bootstrap sweep), each reason naming `test-bootstrap-point-containment.R` as the instrument that does settle it. Checker and its `--self-test` both green.
- 2026-08-05: review collision found that the plan gate missed — RR02's BC6 already required measuring "the frequency of the reported (REML) point lying outside the npbootstrap ICC(1) interval", committed as `point_outside_rate` in the npbootstrap coverage fixture. Same phenomenon, different reducer and a rate rather than a magnitude bound; recorded as prior art, no scope change. The plan-time sweep covered ROADMAP, archive and DECISIONS but not `cairn/reviews/archive/`.

- 2026-08-05: review fan-out — 15 candidate findings across three lenses, one scored >= 80 (F1, 88) and fixed on the branch: the AC4 correction had acquired an unbacked causal clause describing the parametric bootstrap's mechanism inside the `"npbootstrap"` section, where npbootstrap aborts at the boundary and lands strictly below the point just off it. F2 (76) fixed by the same edit, having been verified false against `engine = "lme4"`. F3/F4/F8 logged and carried to a candidate row.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Criterion evidence** (fresh, by command, 2026-08-05; branch at 77b882d, PR #112).

- AC1 — `git ls-files` confirms both artifacts tracked. Fixture schema read back:
  all AC1-named columns present (`arm, n_s, n_r, spread, seed, index, status,
  estimate, conf_low, conf_high, excludes_point, gap`) plus the two refinement
  columns. Returned cells per arm: 12 zero-between, 12 nonzero-between; 0 aborted.
  The nonzero arm carries three distinct `spread` rungs (0.05, 0.3, 1), so the
  between-variance axis is walked, not sampled at one point (GP6).
- AC2 — the fixture-reading test passes. Non-vacuity checked separately: 22
  excluding rows and 17 rows with a point at or above 1e-8 exercise both
  assertions, and a mutated-gap probe reds the bound as required.
- AC3 — paragraph read back verbatim from `R/icc.R`; a grep for numeric literals
  and paths inside it returns exactly two items, `1e-8` and the fixture path, as
  the criterion requires. It sits in the `@param ci_method` `"bootstrap"`
  description, not the `"npbootstrap"` `@details` section.
- AC4 — the corrected sentence reads "sits at, or numerically indistinguishable
  from, `0`"; `grep -n 'point reads' R/icc.R` returns nothing, so the falsified
  claim does not survive anywhere in the file.
- AC5 — the `cairn/DESIGN.md` interval-time Bootstrap row states the relation and
  cites the fixture path; its Source cell now reads `ADR-025; M104`.
- AC6 — the live test passes against the installed package under
  `NOT_CRAN=true CI=true`; it asserts `conf.low > estimate` and both below 1e-8 on
  the pinned 6x3 call.
- AC7 — `devtools::document()` no diff; `lintr::lint_package()` 0 lints;
  `air format --check` exit 0; full suite against the installed package under
  `NOT_CRAN=true CI=true` with failed + error = 0 (23 skips: the live-Stan brms
  set plus `skip_on_cran`).

**Consistency gate.** `cairn_validate` exit 0, all checks passed (the standing
`dangling id tokens` advisory is pre-migration M1-M47 ids, unrelated). No
principle changed, so `cairn_impact` was not run. Profile `consistency-gate`
slot: `document()` no diff, `pkgdown::check_pkgdown()` no problems, NEWS entry
present and free of milestone numbers, new paths covered by existing
`.Rbuildignore` entries (`^data-raw$`).

**Independent review** (three fresh-context lenses + a separate [S] scorer).

- Diff-bug lens **[O]**: 14 candidate findings. Blame-history lens **[S]**: 1
  (F15). Prior-review lens **[S]**: zero findings — it recomputed every numeric
  doc claim against the fixture and confirmed them, and its cheap probe found no
  real inline PR threads on this repo, so the per-PR walk was skipped.
- Scored: one finding at or above 80.

**Actioned — F1 (88), fixed on the branch.** The AC4 correction had gained a
causal clause, "the engine returns a value near but not exactly zero, which is
why a resampled limit can land on either side of it". That is the *parametric*
bootstrap's mechanism, and it sat in the `"npbootstrap"` `@details` section,
whose method is a studentized log-F pivot. Verified live at review: npbootstrap
ABORTS at the exact zero boundary, and just off it (jitter 1e-4, 6x3, seeds 1-3)
`conf.low` is -0.5 against points of ~3e-10 — strictly below the point, never
above. The committed fixture holds zero npbootstrap rows, so the clause was
unbacked (IP1) and directionally false for the method it documented. Removed;
AC4's required correction survives, and RR02 BC5's substance (the unclamped
engine REML point, boundary picture documented) is preserved.

**F2 (76) — below the actioned bar, fixed anyway** by the same edit. The clause
also asserted engine-agnostically that the engine returns a nonzero value, while
`engine = "lme4"` reports "a variance component was estimated at exactly zero"
(verified live). A sentence measured false does not ship on a score.

**Logged, not actioned** (below 80): F4 (70) and F3 (68), the fixture test's
`all()` assertions pass vacuously on zero rows and its anti-vacuity guard checks
a total rather than AC1's per-arm minimum; F14 (52) NEWS omits the AC4
correction; F7 (42) 7 of 24 nonzero-arm rows realize a point below 1e-8, so the
arm label does not track realized variance; F8 (42) `identical()` on a
`data.frame` string column would route the whole grid to the wrong generator
under the declared `R (>= 3.5)` floor; F15 (38) the rewritten sentence was the
literal deliverable of Fable binding condition BC5 (RR02 -> D-010), altered
without a new RB/RR — substance preserved, no test or vignette pins the wording;
F6 (35) the reducer seed is held at 1 across all cells while the data seed
varies; F11 (32) the fixture's `seed` column is the data seed, the reducer seed
lives only in the prose header; F5 (30) the test reads derived columns rather
than recomputing from primitives; F13 (28), F12 (22), F9 (22), F10 (18).

F3, F4 and F8 carry real latent risk and go to a candidate row rather than being
dropped.

**Prior art the plan gate missed.** RR02's BC6 already required recording "the
frequency of the reported (REML) point lying outside the npbootstrap ICC(1)
interval", shipped as `point_outside_rate` in the npbootstrap coverage fixture —
the same phenomenon on the other reducer, bounding a rate where M104 bounds a
magnitude. The plan-time collision sweep covered ROADMAP, archive and DECISIONS
but not `cairn/reviews/archive/`.

**CI defect found and fixed.** `check-references` red: the doc-claims checker
rejected AC3's two sentences as generalizing claims with no ledger row. Both
registered `out` with reasons naming the test that settles them; checker and
`--self-test` green.

**Full check.** `devtools::check(env_vars = c(NOT_CRAN = "false"))` — Status: OK
(0 errors, 0 warnings, 0 notes).
