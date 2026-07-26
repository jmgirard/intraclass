# M93: Boundary-abort hint for the deterministic boundary-robust `ci_method` families

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP7
- **Branch/PR:** `m93-boundary-abort-hint` · https://github.com/jmgirard/intraclass/pull/100

## Goal

When the Monte-Carlo default aborts near the σ²→0 boundary, have the classed error name
an opt-in `ci_method` only after RUNNING that method on the data in hand and seeing a
usable interval — never from a design predicate that tries to anticipate whether it will
work.

## Scope

**In:** a verification step in the abort path that calls the SAME reducer `icc()` would
dispatch to (`searle_ci()`/`burch_ci()`/`mpl_ci()`, `R/icc.R:2098-2109`) with the
`(df, estimands, conf_level)` already in scope, catches every condition, and clears a
method only when every reported endpoint is finite, ordered and in support; the helper
generic over the method name, so M97 adds `npbootstrap` behind it; the design rows kept
as the ADMISSIBILITY filter alone — which strings `icc()` would accept on this design —
with the four predictive inputs (`n_s`/`n_r` for the κ_m grid, `degenerate`, `complete`,
`sb_ok`) deleted; the hint spliced as extra `i =` bullets into the two reachable
Monte-Carlo aborts; NEWS + `@param` docs.

**Out:** `ci_method = "npbootstrap"` → **M97**, which adds it behind this helper plus
the two things unique to a resampling method (RNG neutrality under #9, and what a run
under one seed says about another); the unbalanced one-way row leaves with it, since
`npbootstrap` is the only method shipping that cell (D-013) · re-entering `icc()` per
candidate rather than its reducer — declined at the gate: it re-fits the model and builds
a user-facing result object inside the abort path · fallback or auto-routing on abort,
the `#3`/ADR-003 change D-012 fenced out and D-018 draws the line against → standing
ROADMAP candidate · engine-stage aborts in `R/engine-lme4.R` / `R/engine-lavaan.R`, where
the POINT fit failed and no `ci_method` is a remedy · `R/ci-bootstrap.R:48`, excluded on
T1 evidence (0/90 at the boundary); its own generic remedy names `"montecarlo"`, which
also aborts on the degenerate data reaching it → ROADMAP candidate · identifiability
aborts, which no interval method fixes · any new `ci_method` or a widened fence · a width
or plausibility screen beyond finite/ordered/in-support: `burch` at `unit = 6` gives
`[-15.653, 0.639]`, wide but usable, and D-010's untruncated support admits `searle`'s
legitimate ICC(3) = -1.771 on healthy data.

## Acceptance criteria

- [ ] AC1: a committed reproduction test builds a near-zero-variance dataset on which
      `icc()` aborts `intraclass_singular_fit` through the DEFAULT Monte-Carlo path,
      and the work log records which abort sites that reproduction actually reaches —
      the hint is added only to sites shown reachable, never to sites assumed so.
- [ ] AC2: a method is named only after the verification step returned TRUE for it on
      this data; the abort class, leading message and existing generic remedies are
      unchanged, and a design with nothing to name gains nothing — the hint is additive.
      **Verification can never raise**: every condition a reducer emits is caught, so no
      input turns the boundary abort into a different error (pass-4 F2 did exactly that).
      It is also LAZY — forced only inside an abort message, so a successful call never
      pays for it; a test pins that, and the work log records the measured cost. No
      design names `"npbootstrap"` (→ M97); `R/ci-bootstrap.R:48` excluded on T1 evidence.
- [ ] AC3 (GP7): for every design where the default aborts, every method the message
      names returns a USABLE interval on that same data, and every ADMISSIBLE method the
      message omits really is unusable there. Usable = every reported endpoint finite,
      `conf.low <= conf.high`, and inside the estimand's support under D-010 (ICC(1)
      `(-1/(n₀-1), 1)`; the averaged/projected form `(-∞, 1)`). The in-support clause is
      load-bearing here and was not in the pass-5 predicate: pass-5 F3 (logged at 20) is
      benign only while the MSA = 0 gate and the lower-endpoint pole test exist, and this
      re-cut deletes both — `searle` gives ICC(15) `[1.250, 1.250]` at 100×3, finite and
      ordered and out of support. Asserted by a message-driven sweep that parses the
      names out of the abort `icc()` really raises, over one-way and two-way geometries,
      the silent designs, and the shapes the five review passes came through. **Every
      declared cell asserts a positive number of checks**: a cell that checks nothing
      fails rather than passing silently — pass-3 F4, pass-4 F4 and pass-5 F2 were each a
      tautological or vacuous assertion in this sweep.
- [ ] AC4: the verification cannot drift from the real call — a committed test asserts
      the endpoints it inspects ARE the ones `icc(ci_method = <name>)` reports for that
      method on that data, and that every method an admissibility row offers is accepted
      by `icc()`'s own fence (a named-but-inadmissible method would abort
      `intraclass_unsupported`).
- [ ] AC5: the contract is unchanged — a test asserts the boundary case still aborts
      with class `intraclass_singular_fit` and returns no interval, and that no interval
      computed during verification reaches the message text or any returned object, so
      nothing here implements the D-012-fenced fallback default (D-018).
- [ ] AC6: the change is documented where users meet it — a `NEWS.md` entry saying a
      method is named only after being run on that data, naming the methods and the
      silent designs, and the matching `@param ci_method` note.
- [ ] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; any changed message
      snapshot reviewed deliberately via `testthat::snapshot_review()`, never accepted
      blind; PR #100 green on every job.

**Admissibility rows** (which candidates get RUN; only a usable interval earns a mention):

| design in hand | candidates verified |
|---|---|
| one-way random, balanced | `"searle"`, `"burch"` — D-013's shipped fence |
| two-way random, agreement (`type` unset or agreement), balanced | `"mpl"` — D-014/D-015 |
| anything else, incl. EVERY unbalanced one-way design | none — generic remedies only (M97 revisits unbalanced) |

## Coverage

- AC1 → T4
- AC2 → T1, T2
- AC3 → T4
- AC4 → T3
- AC5 → T2, T4
- AC6 → T5
- AC7 → T5

## Tasks

<!-- Third re-cut 2026-07-26 after the pass-5 gate failure. T1-T12, the first re-cut's
     T1-T5 and the second's T1-T6 are superseded; what they shipped is in the work log. -->

- [x] T1: add the verification helper — generic over a method name, calling the reducer
      `icc()` dispatches to with the same `(df, estimands, conf_level)`, catching every
      condition, returning TRUE only on finite, ordered, in-support endpoints for every
      estimand. Unit tests for each verdict incl. the never-raise obligation; record the
      measured cost.
- [ ] T2: re-cut `boundary_method_hint()` to admissibility + verification — delete
      `boundary_data_degenerate()`, `boundary_sb_safe()`, `boundary_classical_sb_ok()`,
      the `complete` gate and the hint-path `mpl_kappa_available()` call (the lookup
      stays where `R/ci-mpl.R` uses it); keep the design rows as the candidate filter and
      the verdict lazy.
- [ ] T3: the AC4 tests — verified endpoints equal `icc(ci_method = )`'s reported
      interval across a grid of designs, and each admissibility row's methods are
      accepted by `icc()`'s fence.
- [ ] T4: re-cut the AC3 sweep to the new predicate; add the per-cell non-vacuity
      assertion and remove the pass-5 F2 tautology (`expect_gte(checked, 0L)`) and its
      two zero-check `unit` cells. Mutation-verify that dropping verification, dropping
      the in-support clause, and neutering non-vacuity each red it.
- [ ] T5: `NEWS.md` and `@param ci_method` rewritten to the run-it-first surface,
      `devtools::document()`, full AC7 gate, PR #100 green on every job.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the design-aware boundary-abort-hint candidate; plan gate confirmed D-012's fence bites only the fallback DEFAULT, not a message, and scoped engine-stage aborts out pending T1's reachability finding).
- 2026-07-25: implement gate — hint names each qualifying method with its D-012 one-line character (not a bare list, not a single recommendation); unbalanced one-way is worded as availability, not as "succeeds where the default aborts", since D-012's 0-abort evidence is balanced-only.
- 2026-07-25: T1 reachability finding — of the three planned abort sites, `R/ci-montecarlo.R:124` (non-finite draws) fires on 21/40 two-way and 19/40 one-way near-zero datasets, `R/ci-montecarlo.R:43` (non-finite covariance) on 1/40, and `R/ci-bootstrap.R:48` on 0/90 across six boundary geometries. Site C is reachable only by degenerate data (σ²_e = 0, all-identical scores), where npbootstrap/searle/burch/mpl and montecarlo all abort too.
- 2026-07-25: T2 — `R/boundary-hint.R` adds the pure `boundary_method_hint()`; unit tests cover every mapping row plus the empty-hint designs, incl. the unbalanced+numeric-`unit` case (npbootstrap aborts there, so no hint) and the level set read from `kappa_m_table`.
- 2026-07-25: T3 — `hint` threaded through `mc_ci()`/`mc_components()`/`mc_interval()`/`rmvn()` defaulting to `character(0)`; `icc()` builds it from the fence predicates. `rmvn()`'s new arg sits after `call` so the lavaan engine's positional calls are unaffected, and `d_study()` takes the default. Full suite FAIL 0 / PASS 4281 at `NOT_CRAN=true CI=true`.
- 2026-07-25: T4 — AC3 grid guard added (both halves: every named method is accepted, and every silent design's methods really do abort). Mutation-verified: naming `searle` in the two-way random hint reds 4 assertions, and the grid names the offending row.
- 2026-07-25: T5 — NEWS entry + `@param ci_method` note that the abort names the applicable method (the per-method boundary-robustness prose AC6 asks about was already there, so only the pointer was added). Gate: `devtools::check()` 0/0/0, `devtools::test()` FAIL 0 / PASS 4300, `lintr::lint_package()` clean, `air format --check` clean, `document()` no-diff. No message snapshot changed, so none was accepted.
- 2026-07-25: gated amendment — AC2 and Scope narrowed to the two reachable Monte-Carlo sites; `R/ci-bootstrap.R:56` moved to Out with its evidence, and its misleading `montecarlo` remedy carried out as a candidate row.

- 2026-07-25: review pass 1 FAILED the gate — PR #100 CI red on 3 of 7 jobs, one cause: `test-boundary-abort-hint.R:158` errors on Linux/Windows because the glmmTMB point fit raises a raw unclassed `LU factorization` error on the degenerate dataset before any classed guard, and `bh_probe()` catches only `intraclass_singular_fit` (the M84 lesson). Test-only defect; local gate is green and structurally cannot catch it. Status -> in-progress. Two of three review lenses reported 0 findings; the [O] diff-bug lens was still running.
- 2026-07-25: [O] diff-bug lens returned 4 findings; independent scorer gave F1 95 / F2 90 / F3 85 (actioned as T7/T8/T9) and F4 63 (logged, not actioned). F1 and F2 are shipped-behaviour defects of the AC3-forbidden kind (the hint names a method that then aborts) — F1 reproduced independently at review on an 8-subject two-way design. T6 added for the CI failure.
- 2026-07-25: implement gate (pass 2) — F1/F2 reproduced locally, plus a third case of the same shape the findings missed: one-way with all subject means exactly equal hints three methods of which npbootstrap aborts, and all-constant two-way data hints `mpl`, which then raises a raw optim error. Gate decisions: back the hint off on ANY exact degeneracy; ask `mpl_kappa_lookup()` itself whether the geometry is calibrated (one source of truth); amend Scope/AC2/AC3 rather than stretch them.
- 2026-07-25: gated amendment (pass 2) — Scope, AC2 and AC3 now name the two non-fence inputs the hint needs (observed subject/rater counts for `mpl`'s κ_m grid; an exact-degeneracy flag) and the widened AC3 grid (end-to-end through `icc()`, on/off grid geometries, degenerate data); mapping table gains the κ_m-grid condition and a degenerate-data row; Coverage rows extended to map T6–T9.
- 2026-07-25: T6 — the AC2 degenerate-data test now classifies a RAW unclassed point-fit error as "point-fit" and accepts it beside site "C" (`bh_probe_any()`), and the three-method loop no longer pins an abort class glmmTMB does not raise; handler order and raw/classed classification verified by hand. CI is the real check — macOS cannot reproduce the failure.
- 2026-07-25: T7/T8 — the hint now takes the observed `n_s`/`n_r` and a degeneracy flag. `mpl_kappa_available()` (new, `R/ci-mpl.R`) asks `mpl_kappa_lookup()` itself whether a geometry is calibrated, so the grid gate cannot drift from the table; `boundary_data_degenerate()` evaluates the shipped searle/burch/npbootstrap guards' own conditions one-way, and zero total variance two-way (the only cell where mpl breaks — probed). NEWS's exclusion list updated to match. Mutation-verified: dropping the degeneracy return reds 7 assertions, restoring the old conf_level-only mpl gate reds 6.
- 2026-07-25: T9 — AC3's grid is now the grid AC3 enumerates: multilevel, within-cell replicates and an off-κ_m-grid two-way design run end-to-end through `icc()` (silent hint + every opt-in method aborting `intraclass_unsupported`), and the accepted half varies the geometry (10x2 and 15x5, both hinting `mpl` and accepted). Mutation-verified: deleting the multilevel/replicate early return reds the new grid row and names it.
- 2026-07-25: gate green and CI green. Local: `devtools::test()` FAIL 0 / PASS 4367 at `NOT_CRAN=true CI=true`, `devtools::check()` Status OK, `lintr::lint_package()` no lints, `air format --check` clean, `document()` no-diff. PR #100 all 7 jobs pass on 45a4667 — including `ubuntu-latest`, `windows-latest` and `test-coverage`, the three that review pass 1 failed on. Status -> review.
- 2026-07-25: review pass 2 FAILED the gate — the [O] diff-bug lens found the hint still names a `ci_method` that then aborts, on the ONE-WAY rows: `npbootstrap`'s resample-degeneracy guard fires routinely below ~12 subjects (16/16 hinted-then-aborting at n_s=5), and `boundary_data_degenerate()` omits its `se_ij_logf == 0` disjunct. Reproduced by the lens, the independent scorer, and again at the gate. F1 95 / F2 93 / F4 90 actioned as T10-T12; F3 40 logged. AC3 tick withdrawn; the other six criteria verified this pass and stand. Status -> in-progress; second return from review.
- 2026-07-25: implement gate (pass 3) — measured where `npbootstrap`'s resample guard actually bites (25 seeds x 24 balanced cells + 16 unbalanced): it fires routinely below 15 subjects and never at 15+, while `searle`/`burch` aborted 0 times in ~320 hinted runs. Decisive finding: D-012's 0-abort line is a SEARLE/Burch result and was never an npbootstrap result, so the shipped "three interval methods" sentence borrowed evidence that does not exist. Gate: split by evidence (deterministic pair carries the strong claim; npbootstrap only where it is the sole option) with a 15-subject floor.
- 2026-07-25: gated amendment — mapping table split into three one-way rows: balanced names `searle`/`burch` only, unbalanced ≥15 subjects names `npbootstrap` as availability, unbalanced <15 names nothing. AC1-AC7 wording untouched; NEWS updated to match.
- 2026-07-25: T10/T11/T12 — balanced one-way no longer names the bootstrap at any size; unbalanced is floored at `NPB_HINT_MIN_SUBJECTS` (15); `boundary_data_degenerate()` gained npbootstrap's third disjunct `se_ij_logf == 0` and its comment now says it RESTATES the observed-data guards rather than evaluating them, and says why the resample guard is out of its reach. The AC3 grid gained a message-driven one-way sweep over 8 size cells that parses the method names out of the abort `icc()` really raises, so nothing is hand-derived. Mutation-verified: removing the floor reds 6 assertions and restoring the three-method sentence reds 8, both including the new end-to-end grid.
- 2026-07-25: pass-3 gate — `devtools::test()` FAIL 0 / PASS 4453 at `NOT_CRAN=true CI=true`, `devtools::check()` Status OK, `lintr::lint_package()` no lints (it caught the new constant's SCREAMING_CASE name; renamed to `npb_hint_min_subjects`), `air format --check` clean, `document()` no-diff. Status -> review.
- 2026-07-25: CI caught a self-inflicted `check-references` failure — the new test fixture was named for the discrete-outcome axis, falsifying a committed references-page observation that the token is absent from R/ and tests/ (D-009). The claim is TRUE (nothing here handles or studies that axis), so the fixture was renamed rather than the observation weakened; the first rewrite then tripped two more checks by naming both tokens in its own comment.
- 2026-07-25: PR #100 all 7 jobs pass on `3da69d5` — `ubuntu-latest` 16m38s, `windows-latest` 19m25s, `test-coverage` 17m42s, plus `check-references`, `format-check`, `lint`, `pkgdown` and both codecov checks. Ready for review pass 3.
- 2026-07-25: review pass 3 FAILED the gate — AC3 again, on the one-way half. The `n_s >= 15` floor is on the wrong quantity: the resample guard tracks subjects carrying within-subject variance, so the ordinary double-code design (most subjects rated once, a few twice) hints `npbootstrap` and then aborts at EVERY subject count 15-60. T10 also introduced over-suppression: the balanced bullet now stays silent on SSA = 0 data where searle/burch both work. F1 96 / F2 90 / F4 95 actioned-in-principle, F3 76 logged. Two-way/`mpl` clean across 919 hinted runs. THIRD return from review — thrash rule fires, so this is not queued for another implement pass; it goes to `/milestone-plan` for a re-cut. Status -> in-progress.
- 2026-07-25: re-cut by /milestone-plan (gate: split at deterministic-vs-bootstrap). The hint keeps only the deterministic families — `searle`/`burch` balanced one-way, `mpl` two-way — while `npbootstrap` and the whole unbalanced one-way row move to M97 behind a resample-stability predicate; the degeneracy gate goes per-row (pass-3 F2, reproduced at the plan gate on balanced 12x2 SSA=0 data: default aborts, searle/burch both return intervals), and AC3 becomes a message-driven sweep. T1-T12 are superseded but shipped and stay on the branch; T1-T5 are the remainder. Every AC box unticked — the code changes, so each criterion re-verifies from scratch.

- 2026-07-25: T1/T2 (one commit — they rewrite the same twenty lines, so splitting them would have left the suite red at the checkpoint) — `npbootstrap` is named on no design; the unbalanced one-way row, the `npb_hint_min_subjects` floor and the now-unused `unit` argument go with it. The degeneracy check is per-row and forced INSIDE the branch that names a method: the one-way row ASKS `classical_guard_observed()` on a `classical_oneway_ss()` summary instead of restating its condition (the restatement is what drifted at pass 2), the two-way row keeps zero total variance. Mutation-verified: re-naming `npbootstrap` in the balanced bullet reds 30 assertions including the message-driven sweep; restoring the shared OR-gate reds 5, including the SSA = 0 non-vacuity pin.
- 2026-07-25: T3 — AC3's sweep is one `bh_sweep_cell()` helper applied to one-way sizes, two-way geometries on and off the κ_m grid, the no-opt-in designs and all three degenerate shapes: fire the real abort, parse the method names out of the message, run each on the same data. The pass-3 F4 tautology and every npbootstrap-specific test are gone. The SSA = 0 cell asserts it is NON-vacuous, because a "named ⇒ accepted" sweep passes for free on a silenced hint — which is precisely how over-suppression would hide. Measured per cell: balanced one-way names 2 methods per abort across 5 size cells, unbalanced names 0, two-way on-grid names `mpl`, off-grid names 0.

- 2026-07-25: T4 — `NEWS.md` and `@param ci_method` now state the narrowed surface and say WHY the bootstrap is excluded in the user's own terms (whether it succeeds is a property of the resampling, not of their design), rather than listing it among the designs that get nothing; `man/icc.Rd` regenerated. Suite at `NOT_CRAN=true CI=true`: FAIL 0 / PASS 4515 / SKIP 23; `lintr` no lints; `air format` reformatted the rewritten test file and `--check` is clean after.

- 2026-07-25: T5 — gate clean on the final tree: `devtools::check(env_vars = c(NOT_CRAN = "false"))` **Status: OK** (0/0/0, its `checking tests` step running the whole suite in 134s), `devtools::test()` FAIL 0 / PASS 4515 / SKIP 23 at `NOT_CRAN=true CI=true`, `lintr::lint_package()` no lints, `air format --check` clean, `devtools::document()` no-diff. No `_snaps/` path in `git diff --name-only main..HEAD`, so no message snapshot moved and none was accepted. `check-reference-observations.py` 0 falsified and the M74 claim enumerator in sync, so the `check-references` CI job is covered locally. Also retired the superseded task numbers from the test file's section headers, which now name the criteria they serve.

- 2026-07-25: PR #100 all 9 checks green on `5fa3e1c` — `ubuntu-latest (release)`, `windows-latest (release)`, `test-coverage`, `check-references`, `format-check`, `lint`, `pkgdown` and both codecov checks. Status -> review; this is the re-cut's first review pass, and the fourth for the milestone.

- 2026-07-25: review pass 4 FAILED the gate — the forbidden shape is back, via a mechanism no earlier pass touched: a MISSING SCORE. F2 (95) the hint's own degeneracy probe throws `intraclass_unidentified` and replaces the boundary abort (AC2); F1 (94) an NA-carrying two-way design is `balanced` by cell counts, so the hint names `mpl` and `mpl` aborts (AC3); F4 (88) numeric `unit` is no longer an input, so the balanced row steers it into a reversed interval; F3 (87) on the SSA = 0 data this pass deliberately un-suppressed, `searle` returns [-0.5, -0.5] / [-Inf, -Inf] and `burch` returns NaN, so the shipped "return a result" sentence is false — and the plan-gate evidence for that change tested only that no error was raised, never the values. AC2/AC3 ticks withdrawn; AC1, AC4-AC7 stand. Neither my sweep nor the committed one constructs an NA, and both score a method "accepted" iff `icc()` does not raise. FOURTH return from review; thrash-rule disposition left to the maintainer. Status -> in-progress.

- 2026-07-25: CI footnote for the record — on the pass-4 evidence head `349d4bd`, 8 of 9 checks passed (both codecov, `check-references`, `format-check`, `lint`, `pkgdown`, `test-coverage`, `ubuntu-latest`); `windows-latest` shows `cancelled`, killed by the next push rather than failing (the M77/M78 cancel-in-progress behaviour). Moot for the verdict — the gate failed on AC2/AC3, not on CI.

- 2026-07-26: second re-cut by /milestone-plan after the pass-4 gate failure. Gate: PATCH the four findings rather than replace the design→method prediction with running each candidate — verification was measured feasible here (searle 0.17 ms, burch 0.29 ms, mpl 3.5-5.6 ms on an already-failed, lazily-forced path) and prototyped correct on all four findings and both healthy cases, but the maintainer chose the smaller diff; it is now recorded in Scope Out with its measurements, and M97 adopts it for the bootstrap. Two facts settled at the gate: the acceptance predicate is finite-and-ORDERED with no [-1,1] bound, because `searle`'s ICC(3) limit is legitimately -1.771 on healthy data under D-010's `(-∞, 1]` untruncated support; and pass-4 F4 narrows — `searle` reverses at `unit = 6` (`[4.594, 0.602]`) but `burch` returns `[-15.653, 0.639]`, ordered and finite, so `burch` is still named there. Tasks re-cut to T1-T6, one per finding plus the sweep and the gate; AC2 gains a never-raise obligation and AC3 an interval-USABILITY predicate, which is the blind spot both pass-4 sweeps shared.

- 2026-07-26: implement gate (second re-cut) — three decisions, each measured first. (1) The numeric-`unit` rule is the EXACT per-method Spearman-Brown pole test, not a blanket refusal: checked against the real intervals at m = 2,3,4,5,6,10,20 it matches observed reversal in every cell for both methods, and the two differ (searle reverses from m = 5, burch only from m = 10 on the same data), so a shared rule would have to over-suppress one. This corrects the plan-gate line that `burch` is named "either way" — it reverses too, just later. (2) Score completeness gates EVERY row before the design split, one input for one hole. (3) MSA = 0 silences the whole one-way row rather than offering searle's zero-width [-1/(n-1), -1/(n-1)] for the single-rater index alone.
- 2026-07-26: T1-T4 — `boundary_data_degenerate()` now wraps extraction and both guards inside its `tryCatch`, so a probe that cannot be built reads as "this row's methods fail here" instead of replacing the user's abort; `complete = !anyNA(df$score)` gates every row; `isTRUE(ss$msa == 0)` joins the one-way condition; and `boundary_classical_sb_ok()` returns a per-method verdict from each method's own ICC(1) lower endpoint, letting the pair split. End-to-end: `unit = 6` now names burch only, `unit = 10` names neither, an NA score names nothing on either design and keeps class `intraclass_singular_fit`, SSA = 0 names nothing — while healthy one-way still names both and healthy two-way still names mpl 6/6 aborts.
- 2026-07-26: T5 — the sweep's acceptance predicate is now `bh_usable()` (every reported interval finite and `conf.low <= conf.high`), defined once and used by the flag test too; the grid gained the two shapes no earlier sweep had, missing scores and numeric `unit`, plus an AC2 never-raise test over 16 NA-carrying designs. The non-vacuity pin moved onto a two-way cell that must fire, because the SSA = 0 cell that used to carry it is now correctly silent. Mutation-verified, all four fixes: probe-error-not-degenerate reds 3, no completeness gate reds 6, MSA = 0 ignored reds 2, pole test disabled reds 10.
- 2026-07-26: T6 — `NEWS.md` and `@param ci_method` now say a method is named only where it would return a usable interval on that data, checked per method, and name missing scores and the projection limit among the silent cases; `man/icc.Rd` regenerated. M93 test file: 408 assertions, FAIL 0, SKIP 0.

- 2026-07-26: gate clean on the final tree — `devtools::check(env_vars = c(NOT_CRAN = "false"))` **Status: OK** (0/0/0), `devtools::test()` FAIL 0 / PASS 4613 / SKIP 23 at `NOT_CRAN=true CI=true`, `lintr::lint_package()` no lints, `air format --check` clean, `devtools::document()` no-diff. No `_snaps/` path in `git diff --name-only main..HEAD`, so no message snapshot moved. `check-reference-observations.py` 0 falsified and the M74 claim enumerator in sync.

- 2026-07-26: PR #100 all 9 checks green on `dca709a` — `ubuntu-latest (release)`, `windows-latest (release)`, `test-coverage`, `check-references`, `format-check`, `lint`, `pkgdown` and both codecov. Ready for review pass 5.

- 2026-07-26: review pass 5 FAILED the gate — a fifth mechanism, on an axis no pass had varied. F1 (92): `boundary_sb_safe()` validates only the LOWER endpoint, so at exactly 2 subjects with `conf_level` at or past `1 - 2e-8` the hint names `searle`, whose upper endpoint is `NaN` (reproduced here; no violation at 3+ subjects down to `1 - 1e-12`). F2 (88): `expect_gte(checked, 0L)` is a tautology and two of five `unit` sweep cells check nothing — mine, from T5. F3 (20) logged. AC3 tick withdrawn; AC1, AC2, AC4-AC7 stand. Two lenses clean, and the [O] lens ruled out ~1,100 other cells including every axis pass 4 exposed. FIFTH return from review, which is the promotion condition the 2026-07-26 gate recorded verbatim on the verify-instead-of-predict candidate. Status -> in-progress.

- 2026-07-26: third re-cut by /milestone-plan after the pass-5 gate failure. Gate: adopt VERIFY-instead-of-predict for the deterministic methods — the ROADMAP candidate whose recorded promotion condition ("Promote if a fifth mechanism appears") pass-5 F1 meets; the row is absorbed and its lineage ends here. Verification calls the shipped reducers `icc()` dispatches to, not a re-entrant `icc()` per candidate (which would re-fit the model and build a user-facing object inside the abort path); the helper is generic over the method name so M97 adds `npbootstrap` behind it; D-018 records why computing-and-discarding an interval is not D-012's fenced fallback. AC3 gains an in-support clause because pass-5 F3 (logged at 20) is benign only while the MSA = 0 gate and the lower-endpoint pole test exist, and this re-cut deletes both. Every AC box unticked — the code changes, so each criterion re-verifies from scratch.
- 2026-07-26: implement gate (third re-cut) — three things settled by measurement before any code. (1) The in-support cut is `conf.high < 1` with the support OPEN at both ends, implemented exactly as AC3 words it: pole-crossed values have infimum `m/(m-1) > 1` (observed minimum violation 1.164) while legitimate endpoints approach 1 only from below, so no tolerance band is needed; the ICC(1) floor is kept as a rejection even though the classical estimator ATTAINS it, since the support is open there and it never bound on healthy data (0 of 12,600 cells). (2) No point-in-interval requirement — D-010 BC6 accepts the REML point falling outside an interval at the boundary, which is exactly where the hint fires. (3) `icc()` reports reducer endpoints VERBATIM (no clamping anywhere in the reporting path, checked end-to-end), so a reducer-level check is faithful to the user's own call and AC4's equivalence test is well-posed.
- 2026-07-26: gate find, carried OUT of scope to a ROADMAP candidate at the maintainer's call — `icc(model = "oneway", ci_method = "searle", unit = 15, conf_level = 0.80)` on a 2×2 returns `estimate = 5.9e-09` with `[1.153869, 1.164311]`, entirely above 1 and not containing its own point, raising nothing. Pre-existing and not introduced here; 28 of 12,600 healthy cells, `searle` only, `n_s` 2–10, `unit` ∈ {6, 15}, `conf_level` 0.80–0.95. M93 only stops the hint naming it; the defect itself goes to `/hotfix` after M93 merges.
- 2026-07-26: T1 — `boundary_interval_usable()` and `boundary_method_usable()` added; the latter is keyed by `ci_method` string (M97 registers `npbootstrap` by adding a row) and wraps the reducer in `tryCatch` + `withCallingHandlers` so neither an error nor a warning can escape into the user's abort. Measured cost per verified method: searle 0.32 ms, burch 0.44 ms (one-way row 0.53 ms for both), mpl 3.55 ms on-grid and 8.17 ms off-grid — the off-grid case is SLOWER than the deleted `mpl_kappa_available()` lookup because building the abort costs more than the table check, still negligible on a path that has already failed. SSA = 0 measured rather than assumed: searle ICC(1) `[-0.5, -0.5]`, ICC(k) `[-Inf, -Inf]`, burch `NaN` throughout, so the cell pass-3 F2 and pass-4 F3 disagreed about is now settled per estimand by looking.

## Decisions

## Review

**Branch state.** `main` in sync with `origin/main` (0/0); branch 8 ahead / 0 behind,
so no merge was needed before gathering evidence. PR #100.

**Fresh per-criterion evidence** (all from commands run this phase; the M93 test file
runs FAIL 0 / PASS 87 / SKIP 0 at `NOT_CRAN=true CI=true`, 8.5 s):

- AC1 — `test-boundary-abort-hint.R:80` builds the near-σ²→0 dataset and confirms the
  DEFAULT MC path aborts on both designs, that every abort reached is a Monte-Carlo
  site, and that site B is among them. The site enumeration is in this file's work log
  (T1 line, 2026-07-25): `:124` 21/40 two-way + 19/40 one-way, `:43` 1/40,
  `R/ci-bootstrap.R:48` 0/90.
- AC2 — the hint reaches the real abort per design (`:306`), the abort's class, leading
  message and BOTH pre-existing generic remedies survive verbatim while a no-opt-in
  design gains nothing (`:332`), and the bootstrap exclusion carries its own evidence
  (`:122` unreachable at the boundary; `:146` reachable only on degenerate data where
  every named method also aborts). `:386` pins `hint` as defaulted on all four helpers
  and pins `rmvn()`'s argument order so the lavaan engine's positional calls are safe.
- AC3 — the GP7 grid (`:449`) asserts every method the hint names is ACCEPTED by
  `icc()` on that design, across one-way balanced/unbalanced and two-way random with
  both supplied and unset `type`; `:517` asserts the converse, that each design the
  hint stays silent on really does abort for all four opt-in methods.
- AC4 — no-hint designs pinned at `:250` (fixed raters, multilevel, replicates,
  explicit consistency, unbalanced two-way), `:270` (level set read from
  `kappa_m_table`, uncalibrated levels refused), and `:226` (unbalanced one-way with a
  numeric `unit`, where npbootstrap itself aborts).
- AC5 — `:357` confirms the boundary case still raises `intraclass_singular_fit`,
  still returns no `icc` object, and so implements no fallback-on-abort default.
- AC6 — `NEWS.md` carries the user-facing entry under Minor improvements;
  `@param ci_method` gained the pointer that the abort names the applicable method
  (the per-method boundary-robustness prose AC6 makes conditional was already present,
  so only the pointer was owed); `man/icc.Rd` regenerated.

**Consistency gate.** `cairn_validate` exit 0 — all checks PASS including
`coverage complete`; 321 advisory `dangling id tokens`, all pre-existing pre-migration
ids. Profile `consistency-gate` slot: `devtools::document()` no-diff · no generated
file hand-edited · `README.Rmd` untouched · `pkgdown::check_pkgdown()` "No problems
found" · `NEWS.md` entry present · no new top-level files, so no `.Rbuildignore` entry
owed. No `DESIGN.md` principle changed, so `cairn_impact` does not apply.

**GATE FAILURE — CI red, returned to `in-progress` (review pass 1).** 3 of 7 PR #100
jobs fail on ONE cause: `test-boundary-abort-hint.R:158`, the AC2 test asserting the
degenerate 3x2 constant-within-subject dataset reaches the bootstrap abort site.
`test-coverage`, `ubuntu-latest (release)` and `windows-latest (release)` all report
`Error in .local(x, ...): LU factorization of .gCMatrix failed: out of memory or
near-singular`, raised inside `fit_glmmtmb_oneway()` -> `glmmTMB()` -> `TMB::sdreport`
— the glmmTMB POINT fit dies with a RAW, unclassed error before any CI-stage guard
runs, and the test helper `bh_probe()` catches only `intraclass_singular_fit`, so it
escapes. This is exactly the M84 lesson, cited in this test file's own header and then
walked into anyway. `check-references`, `format-check`, `lint` and `pkgdown` pass.

Scope of the defect: TEST-ONLY. No shipped behaviour depends on that assertion, and
the AC2 exclusion of `R/ci-bootstrap.R:48` is strengthened rather than weakened — on
Linux/Windows that dataset does not even reach the bootstrap guard. Note the local
gate CANNOT catch this: macOS glmmTMB completes the same fit, so `devtools::check()`
and the full suite are green locally while three CI jobs are red.

Acceptance checkboxes are deliberately left UNTICKED despite the AC1–AC6 evidence
above: the milestone returns to `in-progress`, and the next review pass re-verifies
from scratch rather than inheriting this pass's evidence.

**Independent review — 2 of 3 lenses reported, both clean.** [S] blame-history: 0
findings (verified the hint is additive at both abort sites, that all four signature
changes stay back-compatible with `engine-lavaan.R`'s positional `rmvn()` calls and
`d-study.R`, and that D-012's fallback-on-abort fence is not crossed). [S]
prior-PR-comments: 0 findings (GitHub inline-comment surface empty by probe; checked
the M92 P6-1 false-"guarded"-claim pattern and found this diff the opposite, since the
guard is a real end-to-end test with a recorded mutation check). The [O] diff-bug lens
was still running when this checkpoint was committed; its findings are to be ingested
as implement tasks.

**[O] diff-bug lens — 4 findings, 3 actioned.** Scored by an independent [S] scorer
that did not generate them.

- **F1 (95) — actioned, T7.** `R/boundary-hint.R:81-94`: the `mpl` hint ignores
  `mpl_kappa_lookup()`'s calibration-grid fence (`R/ci-mpl.R:242-278`, `n_r` in 2..10
  and `n_s` in 10..100), because `icc()` never passes the rater/subject counts to the
  builder. Reproduced independently at review: two-way random balanced, 8 subjects x 3
  raters, the default `ci_method` aborts recommending `ci_method = "mpl"`, and `mpl` on
  that same data aborts `intraclass_unsupported` ("calibrated for 10-100 subjects; this
  design has 8"). Small-`n_s` designs are exactly the ones sitting at the boundary, so
  this is the common case. This is the AC3-forbidden "hint points at another abort", in
  shipped behaviour.
- **F2 (90) — actioned, T8.** `R/boundary-hint.R:56-63`: degenerate data (zero
  within-subject variance) reaches MC site A on the DEFAULT one-way path and receives
  the balanced-one-way hint naming three methods that all abort on it. AC2's exclusion
  reasoning covered site C only; nothing stopped the same degeneracy arriving at site
  A, where the hint does fire.
- **F3 (85) — actioned, T9.** `tests/testthat/test-boundary-abort-hint.R:454-479`: the
  AC3 grid does not realize the grid AC3 enumerates — multilevel and within-cell
  replicates are exercised only as pure-function calls, never end-to-end, and the grid
  never varies `n_s`/`n_r`. That last gap is the mechanism by which F1 shipped green.
- **F4 (63) — below threshold, logged not actioned.** `:386-398` is titled "d_study()
  and the lavaan engine are untouched by the threading" but only inspects `formals()`.
  The scorer judged the title overclaims while the formals checks are genuinely useful
  and other `d_study()` coverage partially mitigates the regression described.

**Open question for the next implement pass** (review does not reinterpret criteria):
F2 sits beside AC2's stated rationale, which is literally true of site C but does not
cover degenerate data arriving at site A. Decide at the implement gate whether AC2/AC3
need a gated amendment or whether the hint guard alone settles it.

---

## Review pass 2 (2026-07-25)

**Branch state.** `main` 0/0 with `origin/main`; branch 14 ahead / 0 behind, so no merge
was needed before gathering evidence. PR #100, head `ea91d09`.

**Fresh per-criterion evidence.** All from commands run this phase. The M93 file runs
**21 tests, 154 assertions, FAIL 0, SKIP 0** at `NOT_CRAN=true CI=true` — the zero skip
count matters, because several tests carry a `skip_if()` on boundary luck and a skipped
one would pass vacuously; none fired.

- AC1 — `:98` builds the near-σ²→0 datasets and asserts the DEFAULT MC path aborts on
  both one-way and two-way, that every abort reached is a Monte-Carlo site (A or B) and
  never the bootstrap site, and that site B occurs. The site enumeration AC1 asks the
  work log to record is there (T1 line, 2026-07-25): `:124` 21/40 two-way + 19/40
  one-way, `:43` 1/40, `R/ci-bootstrap.R:48` 0/90.
- AC2 — the hint reaches the real abort per design (`:342`); the abort's class, leading
  message and BOTH pre-existing generic remedies survive verbatim while a no-opt-in
  design gains nothing (`:368`); the bootstrap exclusion carries its own evidence
  (`:140` unreachable at the boundary, `:164` reachable only on degenerate data where
  every named method also fails). The amended clause — inputs beyond the fence
  predicates — is evidenced at `:596` (counts gate the `mpl` row) and `:696` (the
  degeneracy flag fires exactly where the shipped guards fire, and NOT on σ²→0 boundary
  data, which is the case the hint exists for). `:422` pins `hint` as defaulted on all
  four helpers and pins `rmvn()`'s argument order, so `engine-lavaan.R`'s positional
  calls stay safe.
- AC3 — every design the amended criterion enumerates is exercised END TO END through
  `icc()`, and I checked the enumeration item by item against the file rather than
  trusting the test titles: one-way balanced + unbalanced and two-way random agreement
  (both supplied and unset `type`) at `:485`, each named method actually called and
  accepted; fixed-rater, explicit consistency and an uncalibrated `conf_level` at `:553`;
  multilevel and within-cell replicates at `:846`, run through `icc()` with `cluster =`
  and with replicated cells rather than as pure-function calls; geometry varied on the
  grid at `:821` (10×2 and 15×5, both hinting `mpl` and accepted) and off it at `:629`
  (8 subjects, silent, and `mpl` confirmed to abort there); degenerate data at `:712`.
  **Tick withdrawn — see the gate failure below.** The enumerated grid does pass, but
  AC3's second sentence states the property the grid exists to protect ("a hint that
  points at another abort is a test failure"), and the independent review reproduced
  exactly that in shipped behaviour on the ONE-WAY rows, which the grid never varies in
  size. The criterion is read as written, and as written it is not met.
- AC4 — the five no-opt-in designs the criterion names are each pinned: fixed raters,
  multilevel, replicates and two-way consistency at `:286`, and an `mpl`-shaped design
  at an uncalibrated `conf_level` at `:286`/`:306` (the level set read from
  `kappa_m_table`, so it tracks a recalibration). `:368` is what makes "generic remedies
  alone" testable rather than asserted: a no-opt-in design still carries the pre-existing
  remedies and gains no method name.
- AC5 — `:393` confirms the boundary case still raises `intraclass_singular_fit`, is an
  `rlang_error` and not an `icc` object, so no interval is returned and the
  D-012-fenced fallback-on-abort default is not implemented. The test did not skip
  (SKIP 0 above), so the assertions actually ran.
- AC6 — `NEWS.md` carries the user-facing entry under Minor improvements, updated this
  pass so its no-hint list matches shipped behaviour (it now names a subject/rater count
  outside the calibrated set and degenerate data); `@param ci_method` carries the pointer
  that the abort names the applicable method, with `man/icc.Rd` regenerated in the diff.
- AC7 — all run this phase: `devtools::check(env_vars = c(NOT_CRAN = "false"))`
  **Status: OK** (0 errors / 0 warnings / 0 notes; its `checking tests` step ran the
  suite), `lintr::lint_package()` "No lints found", `air format --check .` clean,
  `devtools::document()` produced an empty `git status`. The snapshot clause is vacuous
  by inspection, not by assumption: `git diff --name-only main..HEAD` contains no
  `_snaps/` path, so no message snapshot changed and none was accepted.

**Consistency gate.** `cairn_validate` exit 0 — 16 PASS including `coverage complete`,
`weight caps`, `mirror agreement` and `at most one in-progress`; advisories only
(`dangling id tokens` 321, all pre-existing pre-migration ids, unchanged by this diff).
Profile `consistency-gate` slot: `document()` no-diff · no generated file hand-edited
(`man/icc.Rd` regenerated from roxygen) · `README.Rmd` untouched · `pkgdown` job green
on PR #100 · `NEWS.md` entry present and updated this pass · no new top-level files, so
no `.Rbuildignore` entry owed. No `DESIGN.md` principle changed (`git diff --name-only`
has no `DESIGN.md`), so `cairn_impact` does not apply.

**CI.** PR #100 on head `ea91d09`: all 7 jobs pass — `ubuntu-latest (release)` 17m21s,
`windows-latest (release)` 20m19s and `test-coverage` 23m54s are the three that failed
review pass 1, and they are the only platforms where the T6 defect reproduces at all.
T6 is therefore verified on the only platforms that can verify it.

**Independent review — 3 lenses.** [S] blame-history: 0 findings (checked D-012/D-013/
D-014/D-015/D-017 against the shipped fences, `rmvn()`/`d_study()`/`engine-lavaan.R`
back-compat, and judged the T6 assertion loosening correct rather than lost coverage —
a class-pinned assertion would be actively wrong on Linux/Windows for that data).
[S] prior-PR-comments: 0 findings (GitHub inline-comment surface empty by probe; F1/F2/
F3 of pass 1 each verified addressed; pass 1's below-threshold F4 carried forward
unchanged, neither regressed nor worsened). [O] diff-bug: 4 findings, scored by an
independent [S] scorer that did not generate them.

**GATE FAILURE — returned to `in-progress` (review pass 2).** The milestone's central
forbidden behaviour is present in shipped code: the hint names a `ci_method` that then
aborts on the same data. Reproduced by the [O] lens, independently by the scorer, and a
third time by me at the gate.

- **F1 (95) — actioned, T10.** `R/boundary-hint.R:97-104` (balanced) and `:109-112`
  (unbalanced) name `ci_method = "npbootstrap"` from the design predicates and the
  exact-degeneracy flag alone, but `npbootstrap_ci()` has a SECOND, non-exact abort —
  the resample-degeneracy guard at `R/ci-npbootstrap.R:178-191`, whose own comment says
  it is "negligibly rare at k >= 10". Below that, it fires routinely. Measured over 25
  seeds/cell on ordinal 1-3 ratings, counting only runs where the default aborted AND
  the hint named npbootstrap, then re-running with npbootstrap: n_s=5 16 hinted/16 then
  abort · n_s=6 15/15 · n_s=8 15/15 · n_s=10 17/12 · n_s=12 18/5 · n_s=15 14/0. Also 9
  of 16 on unbalanced 8-subject data, where npbootstrap is the ONLY method named so the
  whole bullet is wrong. `searle`/`burch` are accepted throughout, so the fix is a size
  gate or splitting the balanced bullet so npbootstrap can be dropped independently —
  the one-sentence, all-three wording is what currently forces all-or-nothing.
- **F2 (93) — actioned, T11.** `R/boundary-hint.R:44-56`: the comment claims it
  evaluates "the shipped guards themselves rather than restate them", but it omits
  `npbootstrap_ci()`'s independent disjunct `obs$se_ij_logf == 0`
  (`R/ci-npbootstrap.R:144`). Any k=2 one-way design with equal within-subject SS hits
  it exactly. The scorer went further than the finding and reached it end-to-end through
  the real hint-firing path, not only by hand construction. Distinct root cause from F1
  (formula gap vs. missing size gate), so it needs its own fix — and the guard-
  equivalence claim in the comment and the T7/T8 work-log line must stop being asserted.
- **F3 (40) — below threshold, logged not actioned.** `R/ci-mpl.R:288-297`:
  `mpl_kappa_available()`'s "cannot drift" comment overclaims, because
  `mpl_kappa_lookup()` checks `n_r` against the global node set and `n_s` against the
  global min/max, then interpolates within the `n_r` column — a ragged table would make
  `approx()` return NA with no condition raised. The scorer verified the shipped table
  is a complete rectangular 9x6 grid at all three levels with an assembly-time
  `stopifnot` in `data-raw/m91-mpl-kappa-sysdata.R`, so there is no live bug; it scored
  40 as fragility against a future edit, not a present defect.
- **F4 (90) — actioned, T12.** `tests/testthat/test-boundary-abort-hint.R:445-454` and
  `:485-551`: pass 1 diagnosed "the grid never varies n_s/n_r" as the mechanism by which
  its own F1 shipped green; T9 fixed that for the two-way/`mpl` rows only.
  `bh_ok_oneway()` is hard-wired to 20 subjects in BOTH the balanced and unbalanced
  rows, which is exactly why F1 above is invisible to a green suite. Secondary: the grid
  computes the hint from hand-written `pred` lists rather than from the predicates
  `icc()` actually derives for that data, so a mis-wiring between the two would not red.

Gate-failure note: this is the milestone's SECOND return from review. A third makes it a
mis-planned milestone under the thrash rule, and the response then is re-plan or split
via `/milestone-plan`, not another retry.

---

## Review pass 3 (2026-07-25)

**Branch state.** `main` 0/0 with `origin/main`; branch 20 ahead / 0 behind. PR #100, head
`3a53993`, all 7 CI jobs green.

**Gate results, all run this phase.** `cairn_validate` exit 0 — 16 PASS including
`coverage complete` and `weight caps`; advisories only, but one is new and pertinent:
`sizing (split tripwires)` now WARNs that M93 carries 12 tasks, past the >10 tripwire.
Profile `consistency-gate`: `devtools::check()` Status OK · `lintr` no lints · `air
format --check` clean · `document()` no-diff · `pkgdown::check_pkgdown()` "No problems
found" · NEWS entry present. M93 test file: 23 tests, 240 assertions, FAIL 0, SKIP 0.
No `DESIGN.md` principle changed, so `cairn_impact` does not apply.

**AC1, AC2, AC4, AC5, AC6, AC7 re-verified and stand** (evidence as recorded in pass 2,
re-run this phase; the test file is green with no skip firing, and the toolchain gate is
clean).

**GATE FAILURE on AC3 — third return from review.** I ran my own sweep, written from the
criterion rather than from the test file: for every design where the DEFAULT aborts, parse
the method names out of the real message and run each on the same data. One-way: 342
aborts, 396 method-names, **4 violations**. Two-way: 151 aborts, 70 method-names, 0
violations. The [O] diff-bug lens found the same class independently and much worse, and
an independent [S] scorer reproduced both.

- **F1 (96) — the floor is on the wrong quantity.** `R/boundary-hint.R:136`. The resample
  guard depends on how many subjects carry within-subject variance, which on unbalanced
  data is decoupled from `n_s`, so `n_s >= 15` never bites. The damning shape is the
  ordinary double-code design — most subjects rated once, a few twice: at 60 subjects with
  3 doubled, the default aborts, names `npbootstrap`, and `npbootstrap` then aborts with
  "115 of 999 resamples were degenerate", at **every** subject count 15-60. My own sweep hit
  it at the floor itself (alternating sizes 2,1 at `n_s` = 15). The suite is green because
  the new sweep's only unbalanced cells are `n_k = 3` (sizes 3,2) — the one imbalance shape
  that never trips the guard. Structurally the same blind spot as pass 2's F4, one level up:
  the grid varies subject COUNT but not imbalance SHAPE.
- **F2 (90) — over-suppression introduced by T10, this pass.** `R/boundary-hint.R:60-72`.
  T10 removed `npbootstrap` from the balanced bullet but left `boundary_data_degenerate()`
  ORing npbootstrap-only disjuncts and gating the WHOLE hint. On balanced data with SSA = 0
  (every subject mean exactly equal, MSE > 0) the hint now says nothing while `searle` and
  `burch` both return intervals. The comment claiming "every method a row below could name
  aborts on them" is false for the balanced row as it now stands.
- **F3 (76) — below threshold, logged not actioned.** `test-boundary-abort-hint.R:559-561`
  runs the hinted `npbootstrap` at `boot_samples = 50L` instead of the shipped 999, cutting
  the chance of tripping a guard that fires on ANY degenerate resample. The scorer confirmed
  the premise but found it masks no live failure on that row today.
- **F4 (95) — actioned.** `test-boundary-abort-hint.R:998` is a tautology
  (`expect_identical(x, x)`) that can never fail; the real check is the next line. Mine,
  from T12. Both the [S] prior-review lens and the scorer flagged it.

**Two lenses clean.** [S] blame-history: 0 findings — it verified against `DECISIONS.md`
and `milestones/archive/M76` that D-012's 0-abort statistic really is SEARLE/Burch-only
(npbootstrap was a comparison incumbent in that sweep), so the two-vs-three split rests on
sound ground; it also noted `R/ci-npbootstrap.R:177`'s "negligibly rare at k >= 10" comment
is now contradicted by measurement, but pre-existing and not introduced here. [S]
prior-review: no regression of any pass-1 or pass-2 finding.

**The two-way half is done; the one-way half is not.** Across this pass's sweeps the `mpl`
row took 849 hinted runs (the lens) plus 70 (mine) with **zero** aborts, at every calibrated
level and on and off the grid. Every failure in all three passes has been one-way, and each
was a different mechanism: the κ_m grid (pass 1), raw subject count (pass 2), effective
subject count and over-suppression (pass 3).

**Thrash rule fires.** This is the third trip back from review, so the response is not
another retry — M93 is mis-cut. The evidence points at the split: ship the two-way/`mpl`
half, and re-plan the one-way half around a predicate for "will the bootstrap resample
stably", which is the question that has defeated three attempts.

---

## Review pass 4 (2026-07-25) — the re-cut

**Branch state.** `main` 0/0 with `origin/main`; branch 27 ahead / 0 behind, so no
merge was needed before gathering evidence. PR #100, head `1064b18`.

**Fresh per-criterion evidence.** All from commands run this phase. The M93 file runs
**302 assertions, FAIL 0, SKIP 0** at `NOT_CRAN=true CI=true` (17.2 s) — the zero skip
count matters, because several tests carry a `skip_if()` on boundary luck and a skipped
one would pass vacuously; none fired.
- AC1 — `:98` builds the near-σ²→0 datasets over 12 seeds each and asserts the DEFAULT
  MC path aborts on both one-way and two-way, that every abort reached is a Monte-Carlo
  site (A or B) and never the bootstrap site, and that site B occurs. The site
  enumeration AC1 asks the work log to record is there (T1 line, 2026-07-25): `:124`
  21/40 two-way + 19/40 one-way, `:43` 1/40, `R/ci-bootstrap.R:48` 0/90. The re-cut did
  not touch this reproduction or its finding.
- AC2 — observed directly this phase, not only through the suite: on a balanced 20×3
  one-way abort the message reads `The Monte-Carlo interval could not be computed: 47%
  of draws were non-finite` with BOTH pre-existing remedies intact (`A variance
  component overflowed…`, `Refit with engine = "glmmTMB" or inspect the model`) and the
  hint appended as a further `i` bullet; the two-way abort carries the `mpl` bullet
  instead; the same two-way data with `raters = "fixed"` aborts with the two generic
  remedies and NOTHING added, which is what makes additivity testable rather than
  asserted. Class `intraclass_singular_fit` throughout. Pinned at `:334` (right hint per
  design), `:363` (additive), `:417` (`hint` defaulted on all four helpers and `rmvn()`'s
  argument order held, so `engine-lavaan.R`'s positional calls stay safe). The per-row
  degeneracy clause is evidenced at `:700`, which asserts the flag agrees with
  `classical_guard_observed()`'s OWN verdict case by case rather than with a copy of its
  condition. `"npbootstrap"` appears in no hint on any design: `:254` sweeps six subject
  counts on unbalanced one-way and `:233` five on balanced, all silent about it.
- AC3 — I ran my own sweep, written from the criterion rather than from the test file:
  for every design where the DEFAULT aborts, parse the method names out of the real
  message and run each on the same data. **153 aborts, 183 method-names, 0 violations.**
  Cells: one-way balanced at 8 subject counts × 3 rater counts × 4 seeds × 2 data kinds;
  one-way unbalanced at 4 subject counts × 3 imbalance SHAPES including the double-code
  shape (most subjects rated once, a few doubled) that defeated pass 3 at every count
  15–60; two-way at 8 subject counts × 5 rater counts, on and off the κ_m grid;
  `conf_level` ∈ {0.80, 0.90, 0.95, 0.975, 0.99}; `type` supplied and unset; fixed
  raters; numeric and string `unit`; and all three degenerate shapes. The committed
  sweep asserting the same property is at `:1054` (one-way sizes) and `:1092` (two-way,
  no-opt-in and degenerate), both driving off `bh_sweep_cell()`, which parses the names
  out of the abort `icc()` really raises. Enumerated designs covered end to end
  elsewhere in the file: multilevel and within-cell replicates at `:905`, geometry
  varied on the grid at `:880` and off it at `:630`, degenerate data at `:750`.
- AC4 — no-opt-in designs pinned at `:277` (fixed raters, multilevel, replicates,
  explicit consistency, unbalanced two-way, unbalanced one-way) and `:298` (the level
  set read from `kappa_m_table`, so it tracks a recalibration rather than pinning
  today's literals). `:363` is what makes "generic remedies alone" testable: the
  fixed-rater abort keeps both pre-existing remedies and gains no method name, which I
  also observed directly above.
- AC5 — `:388` confirms the boundary case still raises `intraclass_singular_fit`, is an
  `rlang_error` and not an `icc` object, so no interval is returned and the D-012-fenced
  fallback-on-abort default is not implemented. The test did not skip (SKIP 0 above), so
  its assertions actually ran.
- AC6 — `NEWS.md` carries the user-facing entry under Minor improvements, rewritten
  this milestone to the narrowed surface: it names `searle`/`burch` and `mpl`, lists the
  designs that get nothing (now including unbalanced one-way), and states in the user's
  own terms why the bootstrap is excluded — whether it succeeds is a property of the
  resampling rather than of their design. `@param ci_method` carries the matching
  pointer and says the abort never names `"npbootstrap"`; `man/icc.Rd` is regenerated in
  the diff.
- AC7 — all run this phase on the final tree: `devtools::check(env_vars = c(NOT_CRAN =
  "false"))` **Status: OK** (0 errors / 0 warnings / 0 notes; its `checking tests` step
  ran the suite in 134s), full suite FAIL 0 / PASS 4515 / SKIP 23 at `NOT_CRAN=true
  CI=true`, `lintr::lint_package()` "No lints found", `air format --check .` clean,
  `devtools::document()` produced an empty `git status`. The snapshot clause is vacuous
  by inspection, not assumption: `git diff --name-only main..HEAD` contains no `_snaps/`
  path, so no message snapshot changed and none was accepted. PR #100 CI: all 9 checks
  green on `5fa3e1c` (both R CMD check platforms, `test-coverage`, `check-references`,
  `format-check`, `lint`, `pkgdown`, both codecov); the four long jobs are re-running on
  the docs-only head `1064b18` and the four fast ones are already green there.

**Consistency gate.** `cairn_validate` exit 0 — 16 PASS including `coverage complete`,
`weight caps`, `mirror agreement`, `at most one in-progress` and `sizing (split
tripwires)`, which the re-cut cleared by going from 12 tasks to 5; advisories only (321
`dangling id tokens`, all pre-existing pre-migration ids, unchanged by this diff).
Profile `consistency-gate` slot: `devtools::document()` no-diff · no generated file
hand-edited (`man/icc.Rd` regenerated from roxygen) · `README.Rmd` untouched ·
`pkgdown::check_pkgdown()` "No problems found" · `NEWS.md` entry present and rewritten
this pass · no new top-level file in the diff, so no `.Rbuildignore` entry owed ·
`devtools::check()` Status OK. No `DESIGN.md` principle changed (`git diff --name-only`
has no `DESIGN.md`), so `cairn_impact` does not apply.

**Independent review — 3 lenses.** [S] blame-history: 0 findings (verified every removed
piece is moot rather than load-bearing, that `classical_oneway_ss()`'s balanced
assumption holds on every path that forces it, and that D-010/D-012/D-013/D-014/D-015
are all still respected). [S] prior-review: 0 findings (the GitHub inline-comment probe
returned `[]`, confirming pass 1's reading of that surface; every actioned finding from
passes 1-3 verified still closed, and the two below-threshold ones not worsened). [O]
diff-bug: 4 findings, every one reproduced by an independent [S] scorer that did not
generate them.

**GATE FAILURE — returned to `in-progress` (review pass 4).** The milestone's central
forbidden behaviour is present again, by a mechanism none of the four passes had
touched: a missing score. All four findings score at or above the action threshold.

- **F2 (95) — the hint machinery destroys the abort it was meant to annotate.**
  `R/boundary-hint.R:59-69`. `npb_groups(df)` and `classical_oneway_ss()` sit OUTSIDE
  the `tryCatch`, so on balanced one-way boundary data carrying an `NA` score, forcing
  the `degenerate` promise inside the abort-message vector raises
  `intraclass_unidentified` ("The one-way bootstrap could not extract complete subject
  rows") and REPLACES the `intraclass_singular_fit` abort — naming a bootstrap the user
  never requested. 8 of 12 cells over `n_s` in {10,20} x `k` in {2,3} x 3 seeds. Breaks
  AC2's "the abort class ... unchanged — the hint is additive". Introduced by T2 this
  pass: swapping in the pre-re-cut `R/boundary-hint.R` gives `intraclass_singular_fit`
  on the same four seeds. Found at this gate and independently by the [O] lens.
- **F1 (94) — the hint names `mpl`, and `mpl` then aborts.** `R/boundary-hint.R:129-150`.
  A two-way random agreement design complete in CELL COUNTS but carrying an `NA` score:
  `balanced` comes from `table(subject, rater)`, which counts the `NA` row as observed,
  and the degeneracy gate misses it because `var(score)` is `NA` so `isTRUE(NA == 0)` is
  FALSE. `mpl_matrix()` then aborts `intraclass_unidentified` on the reshaped cell. 8 of
  8 aborting cells named `mpl` and `mpl` aborted on all 8. This is the AC3-forbidden
  shape in shipped behaviour, on the row three passes had certified clean.
- **F4 (88) — the hint steers a numeric `unit` into a reversed interval.**
  `R/boundary-hint.R:101-119`. T1 removed `unit` from the builder's inputs, so the
  balanced one-way row names `searle`/`burch` unconditionally; with `unit = 6` on
  ordinary boundary data `searle` returns ICC(6) `[1.579, 0.517]` — lower above upper
  and above 1. The pole-crossing arithmetic is pre-existing, but `icc()` fences numeric
  `unit` off the unbalanced npbootstrap path for exactly this reason (`R/icc.R:1417-1431`)
  and the balanced classical path has no such fence. The test file never exercises
  `unit` at all.
- **F3 (87) — "return a result" is false on the data this pass deliberately
  un-suppressed.** `R/boundary-hint.R:36-45`. On the committed SSA = 0 fixture `searle`
  returns ICC(1) `[-0.500, -0.500]` and ICC(k) `[-Inf, -Inf]`, and `burch` returns `NaN`
  throughout, while the message says "Two interval methods return a result for this
  design where the default cannot". **The plan-gate evidence for this change was wrong:
  it tested only that no error was raised and never inspected the returned values** —
  the same error pass-3's own F2 made when it reported that searle and burch "both
  return intervals". DESIGN.md's boundary-fit policy forbids a silent NA interval, so
  the honest reading is that the old suppression was right on this cell for a reason
  nobody had stated.

**Why the pass-4 sweep missed all of this.** My own AC3 sweep (153 aborts, 183
method-names, 0 violations) and the committed one share two blind spots the findings
walk straight through: neither constructs an `NA` score anywhere, and `bh_sweep_cell()`
scores a method "accepted" iff `icc()` does not raise, so a `NaN` or reversed interval
passes. The grid varied designs; it never varied the ACCEPTANCE PREDICATE or the data's
completeness. That is the pass-2 F4 pattern one level along, for the third time.

**AC2 and AC3 ticks withdrawn**; AC1, AC4, AC5, AC6 and AC7 were verified this pass and
stand as recorded above (AC5 is met as written — a test does assert the classed abort on
non-NA boundary data, and no fallback default is implemented; F2's class change is AC2's
business, not AC5's).

**Thrash rule.** This is the FOURTH return from review. The rule fired at the third and
produced this re-cut, so the count is ambiguous and the disposition is the maintainer's:
counting from the re-cut this is the first failure, but counting the milestone it is the
fourth. What is not ambiguous is that F3 is a scope question rather than a bug — whether
the hint should fire on SSA = 0 data at all — and that belongs at a plan gate.

---

## Review pass 5 (2026-07-26) — the second re-cut

**Branch state.** `main` 0/0 with `origin/main`; branch 35 ahead / 0 behind, so no merge
was needed before gathering evidence. PR #100, head `7f78b26`, all 9 CI checks green.

**Fresh per-criterion evidence.** All from commands run this phase. The M93 file runs
**400 assertions, FAIL 0, SKIP 0** at `NOT_CRAN=true CI=true` (18.8 s); the zero skip
count matters, because several tests carry a `skip_if()` on boundary luck.
- AC1 — `:125` builds the near-σ²→0 datasets over 12 seeds each and asserts the DEFAULT
  MC path aborts on both one-way and two-way, that every abort reached is a Monte-Carlo
  site (A or B) and never the bootstrap site, and that site B occurs. The site
  enumeration AC1 asks the work log to record is there (T1 line, 2026-07-25): `:124`
  21/40 two-way + 19/40 one-way, `:43` 1/40, `R/ci-bootstrap.R:48` 0/90. Untouched by
  either re-cut.
- AC2 — the four non-fence inputs are each evidenced: counts at `:626`, the degeneracy
  flag at `:729`, completeness at `:1168`, and the per-method Spearman-Brown verdict at
  `:1228`. Additivity at `:392` (class, leading message and BOTH pre-existing remedies
  survive verbatim while a no-opt-in design gains nothing) and `:446` (`hint` defaulted
  on all four helpers, `rmvn()`'s argument order pinned so `engine-lavaan.R`'s
  positional calls stay safe). The NEVER-RAISE clause — the sharper half, and the one
  pass 4 failed — is at `:1168`: 16 NA-carrying designs across both models, every abort
  reached asserted to be `intraclass_singular_fit` and nothing else. I confirmed the
  same by hand: pre-re-cut code gives `intraclass_unidentified` on that data, HEAD gives
  `intraclass_singular_fit`. `"npbootstrap"` is named on no design (`:262`, `:283`).
- AC3 — I ran my own sweep, written from the criterion and not from the test file, in
  BOTH directions: for every design where the default aborts, parse the method names out
  of the real message, run each on the same data, and require a finite ordered interval
  from `generics::tidy()`; then, for every method the design fence admits that was NOT
  named, check it would not have worked either. **252 aborts, 367 method-names, 0
  named-but-unusable, 0 silent-but-usable.** Cells: one-way at 6 subject counts × 3
  rater counts × 5 data kinds (integer, gaussian, binary, 1e6-scaled, 1e-8-scaled) × 3
  seeds; 9 `unit` variants incl. vectors and numerics; 5 `conf_level`s; two-way at 7
  subject counts × 5 rater counts on and off the κ_m grid, plus type/unit/conf_level/
  fixed-rater variants; `NA` at 4 positions on each model; 3 imbalance shapes at 3
  sizes; and the three degenerate shapes. The committed sweep asserting the same
  property is at `:1040` and `:1078`, with the two shapes no earlier sweep had at
  `:1168` and `:1228`; `bh_usable()` is its single acceptance predicate, used by the
  degeneracy test too.
- AC4 — no-opt-in designs pinned at `:306` (fixed raters, multilevel, replicates,
  explicit consistency, unbalanced two-way, unbalanced one-way) and `:327` (the level
  set read from `kappa_m_table`, so it tracks a recalibration). `:392` is what makes
  "generic remedies alone" testable rather than asserted, and my sweep's zero
  silent-but-usable count is the converse evidence over 252 aborts: no design was
  silenced where a method the fence admits would have delivered.
- AC5 — `:417` confirms the boundary case still raises `intraclass_singular_fit`, is an
  `rlang_error` and not an `icc` object, so no interval is returned and the D-012-fenced
  fallback-on-abort default is not implemented. Worth stating explicitly because this
  pass computes interval ENDPOINTS inside the abort path for the pole test: they decide
  whether to NAME a method and are then discarded, and no code path returns them.
- AC6 — `NEWS.md` carries the user-facing entry under Minor improvements, rewritten
  this pass: it now says a method is named only where it would return a usable interval
  on that data, checked per method, and lists missing scores and the projection limit
  among the silent cases. `@param ci_method` carries the matching wording;
  `man/icc.Rd` is regenerated in the diff.
- AC7 — all run this phase on the final tree: `devtools::check(env_vars = c(NOT_CRAN =
  "false"))` **Status: OK** (0 errors / 0 warnings / 0 notes), full suite FAIL 0 / PASS
  4613 / SKIP 23 at `NOT_CRAN=true CI=true`, `lintr::lint_package()` "No lints found",
  `air format --check .` clean, `devtools::document()` empty `git status`. The snapshot
  clause is vacuous by inspection: `git diff --name-only main..HEAD` contains no
  `_snaps/` path. PR #100 all 9 checks green on `dca709a`.

**Consistency gate.** `cairn_validate` exit 0 — 16 PASS including `coverage complete`,
`weight caps`, `mirror agreement`, `at most one in-progress` and `sizing (split
tripwires)`; advisories only (321 `dangling id tokens`, all pre-existing pre-migration
ids, unchanged by this diff). Profile `consistency-gate` slot: `devtools::document()`
no-diff · no generated file hand-edited (`man/icc.Rd` regenerated from roxygen) ·
`README.Rmd` untouched · `pkgdown::check_pkgdown()` "No problems found" · `NEWS.md`
entry present and rewritten this pass · no new top-level file in the diff, so no
`.Rbuildignore` entry owed · `devtools::check()` Status OK. Also clean: the
`check-references` CI job's two gates locally (`check-reference-observations.py` 0
falsified, the M74 claim enumerator in sync). No `DESIGN.md` principle changed, so
`cairn_impact` does not apply.

**Independent review — 3 lenses.** [S] blame-history: 0 findings (independently
reproduced the SSA = 0 values, judged the re-suppression a correction rather than a
revert, confirmed the blanket `tryCatch` is what AC2 now demands, verified the `complete`
gate silences nothing a method could serve — every named-able method already aborts on
an NA score — and traced D-012's fence as approached but not crossed: the endpoints feed
a boolean and never reach the message or a returned object). [S] prior-review: 0 findings
(GitHub inline-comment probe returned `[]`; every actioned finding from passes 1-4
verified still closed, the three below-threshold ones not worsened, and the pass-3/pass-4
oscillation adjudicated as corrected because the test now checks VALUES rather than
repeating the unverified "they return intervals" claim). [O] diff-bug: 3 findings, all
reproduced by an independent [S] scorer that did not generate them.

**GATE FAILURE — returned to `in-progress` (review pass 5).** A fifth mechanism, on an
axis no earlier pass varied: the confidence level's upper tail at the minimum legal
subject count.

- **F1 (92) — the per-method verdict validates ONE of the two endpoints.**
  `R/boundary-hint.R:99-108` and `:129`/`:142`. `boundary_classical_sb_ok()` extracts
  each method's ICC(1) `[["lower"]]` only; nothing anywhere inspects `[["upper"]]`, while
  AC3's predicate is stated over every reported endpoint. `searle_endpoints()` computes
  `g_hi <- f / qf(alpha/2, df1, df2)`; with `df1 = n_s - 1`, at 2 subjects `df1 = 1` and
  `qf` underflows to exactly 0 once `alpha/2 <~ 1e-8`, so `g_hi` is `Inf` and the ICC is
  `NaN`. Reproduced at this gate: 2 subjects x 4 raters, balanced, complete,
  `conf_level = 1 - 2e-8` — the default aborts, the message names BOTH methods, and
  `searle` returns ICC(1) `[-0.333, NaN]` and ICC(k) `[-72985, NaN]`. My reachability
  map: violations at `n_s = 2` for every `conf_level` at or past `1 - 2e-8`, and none at
  `n_s` in {3, 4, 5, 10} down to `1 - 1e-12` — `icc()`'s validator accepts any level in
  `(0, 1)`, so the input is legal. It also falsifies the `NEWS.md` sentence written this
  pass ("named only where it would return a usable interval on your data, which is
  checked per method"), which becomes true again only once F1 is fixed.
- **F2 (88) — a tautological assertion, and two vacuous sweep cells.**
  `tests/testthat/test-boundary-abort-hint.R:1242`: `expect_gte(checked, 0L)` where
  `checked` counts up from `0L`, so it can never fail. Measured by replaying the cell
  builder: `unit = 2` checks 8 methods, `unit = 3` 8, `unit = 6` 4, `unit = 10` **0**,
  `unit = 20` **0** — two of the five declared cells assert nothing about naming, and the
  pin cannot say so. Mine, from T5, and the same defect class as pass-3 F4 and pass-4 F4.
  The adjacent `split_seen` assertion is real, so the test is not wholly vacuous.
- **F3 (20) — below threshold, logged not actioned.** AC3's finite-and-ordered predicate
  admits an interval lying entirely above +1 (100 subjects x 3, `unit = 15`, searle gives
  `ICC(15) = [1.250, 1.250]`), so the criterion's literal wording is an incomplete
  characterization of "usable". The scorer confirmed the shipped code is correct there —
  that case is caught upstream by the MSA = 0 gate, and monotonicity means a
  lower-endpoint pole test always suppresses when the upper is also past the pole — so no
  code or test change is indicated. Worth knowing when AC3 is next reworded.

**AC3 tick withdrawn**; AC1, AC2, AC4, AC5, AC6 and AC7 were verified this pass and
stand. AC6 is met as written — the entry names the methods and the silent designs — but
its "checked per method" sentence is the claim F1 falsifies, so it is re-verified when F1
lands.

**What the [O] lens ruled out**, so the next pass need not re-tread it: ~1,100 aborting
cells / ~1,600 hinted runs, message-driven, zero other violations — across binary,
Likert, log-normal, t(3), rounded, 1e3- and 1e-3-scaled scores and a single 1e6 outlier;
exact-additive, rater-only, subject-only, constant-rater, constant-subject, all-constant
and `Inf` data; `NA` in the subject/rater LABEL columns as well as in `score`; `n_s`
2-120 x `n_r` 2-12 on and off both κ_m grid edges; three imbalance shapes; replicates and
multilevel; all four engines; and 600 seeded cells comparing the hint live against
`boundary_method_hint()` neutered, with 0 differing error classes — the pass-4 F2 shape
is closed. `mpl` took 4,000 boundary datasets with 0 non-finite or reversed intervals.

**Thrash rule, and what the evidence now says.** This is the FIFTH return from review.
The 2026-07-26 plan gate declined verification for M93 in favour of patching, and
recorded the condition for revisiting verbatim on the ROADMAP candidate: "Promote if a
fifth mechanism appears." One has — and F1 is a textbook instance of the class, a
predictor deriving a TWO-endpoint property from ONE endpoint. Verification would have
caught it without anyone anticipating the axis, because it inspects the interval the user
would actually get. The disposition is the maintainer's; the evidence for it is no longer
an argument from principle.
