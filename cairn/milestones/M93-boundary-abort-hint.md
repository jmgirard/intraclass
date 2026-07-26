# M93: Design-aware boundary-abort hint — name the boundary-robust `ci_method` for the design in hand

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP7
- **Branch/PR:** `m93-boundary-abort-hint` · https://github.com/jmgirard/intraclass/pull/100

## Goal

When the Monte-Carlo default aborts near the σ²→0 boundary, have the classed error
name the boundary-robust opt-in `ci_method` that actually applies to the user's
design, instead of only the generic refit/aggregate remedies.

## Scope

**In:** an internal design→method mapping computed from the predicates `icc()` already
holds at its `ci_method` fences (`R/icc.R:1381-1497`) — `oneway`, `multilevel`,
`replicates`, `raters`, `balanced`, `type`, `conf_level` — plus two inputs review pass 1
proved the mapping cannot be right without: the observed subject/rater counts (the `mpl`
row must respect `mpl_kappa_lookup()`'s κ_m calibration grid) and an exact-degeneracy
flag read from the data, where every method a row would name aborts; threaded as extra
`i =` bullets into the CI-stage `intraclass_singular_fit` aborts in `R/ci-montecarlo.R`
that T1 showed reachable at the boundary; a guard test that every method the hint names
is actually accepted on that design; NEWS + `@param` docs.

**Out:** fallback or auto-routing — the default still aborts; replacing the abort with
a classical interval is the `#3`/ADR-003 contract change D-012 fenced out ("A classical
**fallback-on-abort** default behaviour is a distinct, later `#3` question, not decided
here") and stays its own ROADMAP candidate · engine-stage `intraclass_singular_fit`
aborts in `R/engine-lme4.R` / `R/engine-lavaan.R`, where the POINT fit failed and no
`ci_method` is a remedy → candidate row if T1 shows they matter · `R/ci-bootstrap.R:56`,
excluded on T1 evidence (see AC2); that site's own generic remedy names
`ci_method = "montecarlo"`, which also aborts on the degenerate data reaching it →
ROADMAP candidate row · identifiability
aborts (`intraclass_unidentified`), which no interval method fixes · any new
`ci_method`, or widening an existing one's design fence.

## Acceptance criteria

- [x] AC1: a committed reproduction test builds a near-zero-variance dataset on which
      `icc()` aborts `intraclass_singular_fit` through the DEFAULT Monte-Carlo path,
      and the work log records which abort sites that reproduction actually reaches —
      the hint is added only to sites shown reachable, never to sites assumed so.
- [x] AC2: `icc()` derives the hint from the predicates it already computes and passes
      it to the two Monte-Carlo boundary aborts T1 showed reachable
      (`R/ci-montecarlo.R:43` non-finite covariance, `:124` non-finite draws); the abort
      class, the leading message, and the existing generic remedies are all unchanged —
      the hint is additive. `R/ci-bootstrap.R:48` is excluded on T1 evidence: it is
      unreachable at the σ²→0 boundary (90/90 refits converged across six geometries
      including exact-zero σ²_s at 5 subjects × 2) and is reached only by degenerate
      data (σ²_e = 0, all-identical scores) on which every method the mapping table
      would name ALSO aborts — so a hint there would point at another abort, which AC3
      forbids. The hint's inputs also include the observed subject/rater counts and an
      exact-degeneracy flag, not the fence predicates alone (review pass 1, F1/F2): a row
      is named only when the design AND the data in hand accept it.
- [x] AC3 (GP7): a test asserts over a design grid — one-way balanced and unbalanced,
      two-way random agreement and consistency, fixed-rater, multilevel, and
      within-cell-replicate, each exercised end-to-end through `icc()`, at subject/rater
      counts both on and off `mpl`'s κ_m calibration grid, and on exactly-degenerate
      data — that every `ci_method` the hint names is ACCEPTED by `icc()` there. A hint
      that points at another abort is a test failure, so a later fence change cannot
      silently rot the mapping.
- [x] AC4: designs with no boundary-robust opt-in — fixed raters, multilevel,
      replicates, two-way consistency, and an `mpl`-shaped design at a `conf_level`
      outside the calibrated set — receive NO method hint; a test pins the message to
      its generic remedies alone (a blanket "try mpl" is wrong off two-way random
      agreement).
- [x] AC5: the contract is unchanged — a test asserts the boundary case still aborts
      with class `intraclass_singular_fit` and returns no interval, so nothing here
      implements the D-012-fenced fallback default.
- [x] AC6: the change is documented where users meet it — a `NEWS.md` entry, and the
      `@param ci_method` boundary-robustness note updated if it does not already say
      an opt-in method exists for the aborting cases.
- [x] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; any changed message
      snapshot reviewed deliberately via `testthat::snapshot_review()`, never accepted
      blind.

**Mapping to implement** (each row mirrors a shipped fence; AC3 is what keeps it true):

| design in hand | hint names |
|---|---|
| one-way random, balanced | `"npbootstrap"`, `"searle"`, `"burch"` (D-006/D-010, D-012/D-013) |
| one-way random, unbalanced | `"npbootstrap"` only — `"searle"`/`"burch"` are balanced-only |
| two-way random, agreement, balanced+complete, calibrated `conf_level` **and a geometry on the κ_m grid** | `"mpl"` (D-014/D-015) |
| exactly-degenerate data (zero within- or between-subject SS one-way; constant scores two-way) | nothing — every method above aborts (F2) |
| anything else | nothing — generic remedies only |

## Coverage

- AC1 → T1
- AC2 → T2, T3, T6, T7, T8
- AC3 → T4, T7, T8, T9
- AC4 → T2, T8
- AC5 → T3, T4
- AC6 → T5, T7
- AC7 → T5

## Tasks

- [x] T1: Write the failing reproduction test first: a near-σ²→0 dataset that reaches
      `intraclass_singular_fit` via the default MC path. Then enumerate which of
      `R/ci-montecarlo.R:54`, `R/ci-montecarlo.R:131` and `R/ci-bootstrap.R:56` that
      reproduction actually fires, and log it — M84 showed an engine point-fit can
      crash first and leave a downstream guard unreachable.
- [x] T2: Add the internal hint builder — a pure function of the fence predicates,
      returning a possibly-empty character vector of `i =` bullets — with unit tests
      covering every row of the mapping table, including the empty-hint designs.
- [x] T3: Thread the hint from `icc()` into `mc_ci()`/`mc_components()`/`rmvn()` as an
      argument defaulting to none, so no other caller changes, and append it to the two
      reachable abort sites from T1 (`bootstrap_ci()` dropped by the AC2 amendment).
- [x] T4: Add the GP7 guard test: for each design in the AC3 grid, call `icc()` with
      every `ci_method` the hint names and assert it does not abort.
- [x] T5: NEWS entry, `@param ci_method` touch-up, `devtools::document()`, snapshot
      review, full AC7 gate, PR.
- [x] T6: Fix `test-boundary-abort-hint.R:158` — the AC2 degenerate-data test must
      tolerate the glmmTMB point fit dying with a RAW unclassed error (M84), not only
      the classed `intraclass_singular_fit`. Re-verify on CI, not just locally: macOS
      completes the fit that Linux/Windows abort on, so a green local gate proves
      nothing here.
- [x] T7 (review F1, 95): pass `n_s`/`n_r` into `boundary_method_hint()` and gate the
      `mpl` row on `kappa_m_table`'s node set, so the hint stops naming `mpl` on
      designs `mpl_kappa_lookup()` refuses; add an off-grid row to the AC3 grid.
- [x] T8 (review F2, 90): stop the balanced-one-way hint firing on degenerate data
      (zero within-subject variance) that reaches MC site A, where `searle`/`burch`/
      `npbootstrap` all abort. Decide at the implement gate whether AC2/AC3 need a
      gated amendment or the guard alone settles it.
- [x] T9 (review F3, 85): extend the AC3 grid to the enumeration AC3 states —
      multilevel and within-cell replicates end-to-end through `icc()`, not only as
      pure-function calls — and vary `n_s`/`n_r` so an off-grid `mpl` design is covered.

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
