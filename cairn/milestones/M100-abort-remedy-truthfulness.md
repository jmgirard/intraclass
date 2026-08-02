# M100: Abort remedies name only a `ci_method` measured to work on the data that triggers them

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6, GP7
- **Branch/PR:** `m100-abort-remedy-truthfulness` · https://github.com/jmgirard/intraclass/pull/108

## Goal

Every CI-stage abort raised by data degeneracy names an alternative `ci_method`
only where a seeded sweep of that abort's own trigger condition shows the named
method returning a usable interval.

## Scope

**In:** the four reducer-stage aborts whose remedy bullets name
`ci_method = "montecarlo"` on data that has already defeated a variance-based
method — `bootstrap_ci()`'s refit-convergence guard (`R/ci-bootstrap.R:48`),
`classical_guard_observed()`'s MSE = 0 / non-finite-F guard (`R/ci-classical.R`),
and `npbootstrap_ci()`'s observed-data and degenerate-resample guards
(`R/ci-npbootstrap.R`). A committed enumeration of those sites, a committed
seeded sweep measuring each named method against each site's trigger class, the
message rewrites the sweep condemns, direct-at-reducer regression tests, a NEWS
entry, and a D-entry setting the evidence bar for static remedy text.

**Out:** `icc()`'s pre-dispatch design and argument fences (`R/icc.R:605`, `615`,
`1423`, `1444`, `1453`, `1480` and siblings) — they refuse a *design*, not
degenerate data, and the default they name works there; excluded at the plan
gate (2026-08-01) and not revisited absent evidence one of them misleads.
Extending M93's runtime `boundary_method_hint()` to these sites → rejected at the
plan gate, ROADMAP candidate row with its promotion condition. A committed ledger
plus CI checker pinning this rule against future edits → ROADMAP candidate row
(user's choice at the plan gate over a follow-on milestone). The
fallback-on-abort default D-012/D-013 fenced out stays fenced: no abort here
returns an interval, only message text changes.

## Acceptance criteria

- [ ] AC1 A committed script enumerates the CI-stage aborts under `R/` whose
      trigger is observed-data or resample degeneracy and whose remedy bullets
      name a `ci_method` value, emitting per site the file, the triggering
      condition, and the method string(s) named. The committed enumeration is
      that script's own output. Its site predicate is the reducer-stage
      degeneracy trigger, so `icc()`'s pre-dispatch design fences do not appear.
- [ ] AC2 For each enumerated site, a committed seeded script sweeps several
      geometries satisfying that site's trigger condition and records, per
      dataset, that the abort fires — caught as its classed condition from the
      reducer called directly — and, for each `ci_method` that site's remedy
      names, whether that method returns a usable interval on the same data,
      judged by the shipped `boundary_interval_usable()` (`R/boundary-hint.R`)
      rather than a predicate written for this milestone. Every outcome in the
      record comes from a run.
- [ ] AC3 No shipped remedy bullet at an enumerated site names a `ci_method`
      that the AC2 sweep found failing on any of that site's swept datasets.
- [ ] AC4 Each site whose bullets change keeps the condition class and the
      leading message line it signalled before this milestone, and its message
      still tells the user something to act on — what about their data is
      degenerate, or a method the sweep found usable there.
- [ ] AC5 Each changed message is pinned by a test that fires the abort at its
      reducer directly rather than through `icc()`, asserting the property AC3
      states rather than the literal sentence; each pin is mutation-verified by
      restoring the pre-milestone bullet and recording that the suite reds.
- [ ] AC6 `NEWS.md` records the changed messages, and `cairn/DECISIONS.md` gains
      an entry setting the evidence bar for *static* remedy text naming a
      `ci_method` — a sweep over that abort's trigger class — and stating how it
      stands to D-018's runtime-verification route and D-019's name-no-method
      precedent.
- [ ] AC7 The profile `verify` slot is clean, plus the fuller pre-review check it
      names, with every `data-raw` checker run locally.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2, T3
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1 `data-raw/enumerate-ci-method-remedies.py` — scan `R/ci-*.R` for classed
      aborts whose message bullets name a `ci_method` value and whose trigger is
      observed-data or resample degeneracy; commit its output table.
- [x] T2 `data-raw/sweep-abort-remedies.R` — per enumerated site, generate
      several geometries meeting its trigger condition, confirm the abort fires
      from the reducer called directly, run each named method, and classify the
      result through `boundary_interval_usable()`; commit the results table.
- [x] T3 Rewrite the remedies T2 condemns, at each site keeping its abort class
      and leading line: `bootstrap_ci()` (`R/ci-bootstrap.R:48`),
      `classical_guard_observed()` (`R/ci-classical.R`), and the two
      `npbootstrap_ci()` degeneracy guards (`R/ci-npbootstrap.R`).
- [x] T4 Tests firing each rewritten abort at its reducer directly — a stub
      `simulate_refit` for the bootstrap site, raw degenerate frames for the
      others — asserting no condemned method is named; mutation-verify each by
      restoring the old bullet.
- [x] T5 `NEWS.md` entry, the `cairn/DECISIONS.md` entry, and any snapshot
      refreshed by the changed text.
- [x] T6 Gate: full suite at `NOT_CRAN=true CI=true`, `lintr::lint_package()`,
      `air format --check`, and every `data-raw` checker.

## Work log

- 2026-08-01: created by /milestone-plan; absorbs the ROADMAP candidate row on `R/ci-bootstrap.R:48`'s untruthful remedy (lineage M93 T1 → M93 AC2 amendment → M93 re-cut → here).
- 2026-08-01: plan gate chose all four reducer-stage sites over the bootstrap site alone because one sweep harness covers all four and three known-misleading messages would otherwise ship; falsified by evidence a sibling's trigger set differs enough that one harness cannot reach it.
- 2026-08-01: plan gate chose a seeded sweep of each trigger class over a single triggering dataset per site because static text must hold for every dataset reaching that abort and D-018 records that one run is evidence about one seed; falsified by evidence a site's trigger condition admits only one dataset shape.
- 2026-08-01: plan gate chose rewriting static message text over splicing M93's runtime `boundary_method_hint()` into these sites because M93 T1 measured the bootstrap site 0/90 at the boundary and every candidate method aborting on the degenerate data that does reach it, so the machinery would emit nothing; falsified by a measured trigger dataset where some shipped `ci_method` returns a usable interval.
- 2026-08-01: plan gate chose a ROADMAP candidate row over a follow-on milestone for the ledger + CI checker, at the user's direction.
- 2026-08-01: criteria audit ([O], fresh context) returned six findings; five fixed before the gate — scope narrowed to reducer-stage degeneracy aborts (the `icc()`-body fences have no reducer, so the draft AC2 was unsatisfiable there), the invented three-way outcome classification replaced by the shipped `boundary_interval_usable()`, AC4's vacuous "each rewritten abort" quantifier bound to the audited set, the rewritten remedy required to stay actionable (#8/GP1) rather than merely losing a bullet, and AC6's rule scoped to static text so it cannot contradict D-018's runtime route. The sixth (evidence bar) went to the gate as a question.

- 2026-08-01: T1 — the enumerator finds 9 `ci_method`-naming aborts in `R/ci-*.R`; the committed ledger classifies 4 `sweep` (bootstrap refit-convergence, classical MSE = 0, npbootstrap observed-degeneracy and degenerate-resample) and 5 `fence` (bootstrap engine capability, three mpl grid/level fences, the npbootstrap Spearman-Brown pole — the last on M93's measurement that it fires on healthy cells). Ledger keys are sha1 of the leading message line, stable under this milestone by AC4.
- 2026-08-01: T1 minor plan refinement — the enumerator emits ALL `ci_method`-naming reducer aborts and the ledger records each one's disposition, rather than a regex encoding "degeneracy-triggered" and silently omitting the rest. AC1's property is unchanged (`icc()`'s pre-dispatch fences do not appear — they are out of file scope) and a new abort can no longer escape unclassified.
- 2026-08-01: T1 parser defect found and fixed before commit — the first draft reported an early-return guard as an abort's trigger, INVERTING it (`npb_guard_sb_pole()` aborts when `any(denom < 0)`, above which sits `if (!any(denom < 0)) return(...)`); the condition scan now accepts only an `if` block still open at the abort line.
- 2026-08-01: T1 mutation-verified — leaking the leading line into the remedy scan reds 3 self-test assertions, narrowing the file glob reds 4, deleting a ledger row reds `--check`, and tampering with the committed enumeration reds the freshness gate. All four restored green.

- 2026-08-01: T2 — the sweep measures every candidate method at each `sweep` site, not only the one the shipped text names, so a rewrite can name a working method where one exists. Verdicts over the datasets that reached each site: bootstrap refit-convergence 6 reached, all five candidates usable on 0; classical MSE = 0, 4 reached, all five usable on 0; npbootstrap observed-degeneracy 8 reached, four candidates usable on 0 and `bootstrap` on 4 of 8 (partial, so not nameable in static text); npbootstrap degenerate-resamples 9 reached, `montecarlo` usable on 9 of 9.
- 2026-08-01: T2 decisive finding — three of the four `sweep` sites can name NO method truthfully, and the fourth's shipped `montecarlo` remedy is TRUE and needs no rewrite. The observed data at the resample-guard site is healthy (only the resamples degenerate), which is why the default still works there. T3 rewrites three messages, not four.
- 2026-08-01: T2 — near-degenerate cells (jitter SD 1e-8) do not reach the exact-equality guards at all, and one exact cell (10x2 MSE = 0) killed the glmmTMB point fit with a raw unclassed error before the bootstrap guard, reproducing M93's platform finding on macOS. Both are recorded as "site not reached" with the reason rather than counted as evidence either way.
- 2026-08-01: T2 — constants renamed to snake_case before commit per the M62 lesson (`lintr`'s `object_name_linter` rejects UPPERCASE in `data-raw/` and `air` does not catch it); `lintr::lint()` clean on the new script, `air format --check` clean repo-wide.

- 2026-08-01: T3 — the three condemned bullets now name no method and point at the data instead ("Inspect the ratings: every rater gave each subject the same score"), each keeping its class and leading line; each site carries a comment recording that the old name was measured false and that re-naming needs sweep evidence (GP7). The resample-guard site keeps its `montecarlo` bullet with a comment recording why it survived — its observed data is healthy.
- 2026-08-01: T3 — the three rewritten sites leave the enumeration by the same predicate that admitted them (they no longer name a `ci_method`), so their ledger rows were removed rather than re-dispositioned; a future edit restoring a method name reappears UNCLASSIFIED and reds `--check`. The enumerator's self-test is now two-sided: it pins that method-naming sites are found AND that these three stay out.
- 2026-08-01: T3 — suite green at `NOT_CRAN=true CI=true` (FAIL 0, PASS 5435, SKIP 23) with no test touched, because NO test pinned the remedy text at any of the three sites. That absence is how the untruthful text shipped and survived M93's ten review passes; T4 closes it.

- 2026-08-01: T4 — `tests/testthat/test-abort-remedy-truthfulness.R` (23 assertions) fires every site at its reducer: a stub `simulate_refit` for the bootstrap guard (arithmetic only, no fit, so no platform dependence) and raw degenerate frames for the rest, covering both disjuncts of the npbootstrap observed-data guard. Assertions are on the PROPERTY — `art_named_methods()` returns the methods a message sends the user to — so rewording the guidance stays free while re-naming a method reds (the M68 pin-the-property lesson).
- 2026-08-01: T4 mutation-verified, `testthat.progress.max_fails` raised per the M98 lesson: restoring the old bootstrap bullet reds 2, the classical bullet 2, the npbootstrap bullet 3, and stripping the KEPT `montecarlo` bullet off the resample guard reds 1. All four restored green; full suite at `NOT_CRAN=true CI=true` FAIL 0 / PASS 5458 / SKIP 23.

- 2026-08-01: T5 — self-caught before commit, the M72 trap (violating a lesson in the prose written to record it): the first drafts of all three bullets and the NEWS entry claimed "every other interval method was measured failing", which the sweep falsifies at the npbootstrap observed-degeneracy site, where the parametric bootstrap is usable on 4 of 8. Rewritten so the bullets claim NOTHING about other methods and state only what each guard's own condition establishes; the measurement, with its partial case, lives in the source comments and D-020. The bullets are now unfalsifiable by a method that later turns out to work.
- 2026-08-01: T5 — `NEWS.md` bullet added; `cairn/DECISIONS.md` gains D-020 (static remedy text needs swept evidence over the whole trigger class; confirms D-018's runtime route and generalizes D-019's name-no-method precedent; D-012/D-013's fallback fence untouched). No snapshot referenced the changed text, so none needed refreshing.
- 2026-08-01: T5 — mutations re-run against the FINAL wording, since the earlier evidence described superseded text: restoring each pre-milestone bullet reds 2 / 2 / 3 and stripping the kept bullet reds 1; restored green. Full suite FAIL 0 / PASS 5458; all four `data-raw` checkers and `air format --check` clean.

- 2026-08-01: T6 gate clean — suite `NOT_CRAN=true CI=true` FAIL 0 / PASS 5458 / SKIP 23; `lintr::lint_package()` no lints; `air format --check` clean; `devtools::document()` no diff; all five `data-raw` checkers pass; `cairn_validate` 7 OK / 0 FAIL (321 pre-existing dangling-id advisories); plan-owned body 104/149. `data-raw/` is already `.Rbuildignore`d, so the new scripts owe no entry. Status -> review.

- 2026-08-01: review pass 1 FAILED the gate (first return). [O] diff-bug found the milestone's own defect class surviving in its output: the npbootstrap observed-data bullet is false on healthy data (`se_ij_logf == 0` fires with a finite log F — reproduced at review, scored 93) and the bootstrap bullet asserts a single cause the milestone's OWN sweep contradicts on its jitter cells (90). Seven further >=80 findings are evidence-quality: a wrong `class` column (92), a broken `generator` provenance column (94), a stale sweep header whose keys no longer resolve (92), reached-vs-usable measured on inconsistent paths so two verdict denominators are overstated (82), `boot_samples = 99` against a shipped 999 contradicting the M97 lesson (80), a paren-in-comment parser defect (82), and NEWS inheriting the first error (82). 19 sub-80 findings logged in the Review section. [S] blame-history and [S] prior-review: 0 findings each. Every acceptance box unticked; the next pass re-verifies from scratch. Status -> in-progress.

- 2026-08-01: CI lint red on `data-raw/sweep-abort-remedies.R:234` — `assignment_linter` rejecting `<<-`, the M95 lesson biting exactly as written (local `lintr::lint_package()` said no lints; CI's newer lintr flags it). The grid builder now accumulates with `grid <- c(grid, list(cell_spec(...)))` instead of a helper superassigning to an enclosing `grid`. The `<<-` uses in `tests/` are untouched and were not flagged: they write to a counter in an enclosing `test_that()` closure, while this one wrote to a top-level binding. Re-run reproduces the sweep TSV byte-identically (205 rows), so the refactor is behavior-preserving.

- 2026-08-01: CI green on `3caaa7e` — all nine checks pass (lint, check-references, format-check, pkgdown, test-coverage, codecov patch+project, ubuntu-latest and windows-latest release). The branch is CI-clean; what remains open is the review gate's own findings, not the toolchain.

- 2026-08-01: implement pass 2 (review return) — A1 fixed at the root: `npbootstrap_ci()`'s observed-data guard has THREE causes, not two, and the message now reads the cause off the condition (`log F` = -Inf, `log F` non-finite, or a zero jackknife SE with a finite `log F`) instead of asserting a representative one. A4 fixed the same way on the classical guard's two disjuncts. Verified live on the exact dataset that falsified the old text.
- 2026-08-01: implement pass 2 — A2 fixed: the bootstrap convergence guard now asserts NO cause. It fires on a refit count that no single data fact entails, and the milestone's own sweep contradicted the claimed one on its jittered cells; the hedged bullet above it already carries the usual causes. Its comment also corrects the mechanism — the parametric bootstrap simulates from the fitted model, it does not resample ratings.
- 2026-08-01: implement pass 2 — tests grew from 23 to 45 assertions: a per-branch cause test (each branch says its own thing, and no two branches' claims co-occur), an AC3 case for the SE-zero branch the sweep never generated, and a bootstrap test pinning that no single cause is asserted. The actionability assertion was relaxed from the literal `Inspect the ratings` to the imperative alone — it went red when the bootstrap bullet correctly became `Inspect the fitted model and the ratings behind it`, which is the M68 pin-the-property lesson landing on my own test.
- 2026-08-01: implement pass 2 — enumerator: B5 fixed by resolving each wrapper's class from `R/abort.R` (5 of 6 sites had read `(default)`); B1 fixed by making `_slice_call` carry string state ACROSS lines while skipping comments. A first, line-local comment stripper broke on `R/ci-mpl.R`'s `(#5)` sitting on a string continuation line, merging two mpl sites — caught by the self-test, which is why both hazards now have their own synthetic probes. Mutation-verified: dropping comment-awareness reds the paren probe, dropping wrapper resolution reds the class probe.
- 2026-08-01: implement pass 2 — sweep: C3 raised `boot_samples` to the shipped 999 (the M97 lesson: measure at the count the user's retry uses); C5 carries the generator NAME through `cell_spec()` so every row traces to its generator; C7 dropped the hardcoded per-site `names` in favour of reading the live enumeration, and the header no longer claims the ledger is the site source (the site set is fixed by the code — a guard stays worth measuring after it stops naming a method); C2 records `point_fit_ok` and counts a cell as evidence only when a user could actually reach the message. A `gen_se_zero` cell covers the branch A1 exposed.
- 2026-08-01: CORRECTION superseding the 2026-08-01 T2 verdict line — its per-site reach counts were inflated by C2. Cells where the glmmTMB point fit dies before any CI-stage guard were counted as reached, though no user could see the message on that data. The corrected denominators come from the pass-2 re-run; the qualitative verdict (no method usable across the trigger class at three sites, `montecarlo` usable at the resample guard) is unchanged.

- 2026-08-01: implement pass 2 — corrected sweep verdicts (210 rows, boot_samples 999, point-fit-gated denominators). Bootstrap refit-convergence: 6 reached, all five candidates 0/6. Classical MSE = 0: 3 reached (was 4 — the 10x2 cell's point fit dies, so no user could meet that message there), all five 0/3. npbootstrap observed-degeneracy: 8 reached, `montecarlo` 1/8, `searle` 1/8, `burch` 1/8, `bootstrap` 5/8, `npbootstrap` 0/8 — every one PARTIAL, so still nameable by none. npbootstrap degenerate-resamples: 9 reached, `montecarlo` 9/9, unchanged.
- 2026-08-01: implement pass 2 — the new `gen_se_zero` cell changed a verdict, which is why the gap mattered: `montecarlo` is usable on it (the data is healthy), so the npbootstrap observed-degeneracy site is no longer '0 of 8' but '1 of 8'. The shipped text is unaffected — partial is not nameable — but the RATIONALE was: the NEWS bullet's blanket 'usable on none of them' was false for that site and is rewritten to say what the sweep actually found. The source comment survived unedited because it already said 'none usable ACROSS this guard's trigger class', which 1/8 satisfies.
- 2026-08-01: implement pass 2 gate — suite `NOT_CRAN=true CI=true` FAIL 0 / PASS 5480 / SKIP 23 (45 in the new file, up from 23); `lintr::lint_package()` no lints; `air format --check` clean; all four other `data-raw` checkers pass; `cairn_validate` no FAILs.

- 2026-08-01: review pass 2 FAILED the gate (SECOND return). [O] diff-bug found 3 findings >=80: a crash this milestone introduced (`if (NA)` on a NaN MSE, unclassed `simpleError` where main raised a classed abort, 96, reproduced at the gate); the completeness gate blind at the two refactored sites while the ledger, the self-test comment and D-020 all claim it guards them (92, reproduced at the gate); and the pass-1 false-cause defect surviving inside its own repair, NaN conflated with overflow (80). 17 sub-80 findings logged, incl. D-020's sweep parenthetical being backwards (78). Both [S] lenses 0 findings. Thrash trigger (b) fires on AC4 -- twice failed, same shape, new mechanism -- and the plan gate recorded no alternative for how a message should describe a cause, so the disposition goes to the maintainer with an escalation offer. Status -> in-progress.

- 2026-08-01: implement pass 3 (second review return). Maintainer's disposition at the pass-2 gate: these guards REPORT the quantities that failed and diagnose nothing. Both messages lost their branching entirely, which removes F1 and F2 by CONSTRUCTION rather than by patching their corners — there is no second predicate left to evaluate on a NaN, and no prose cause left to be false. The classical guard's remaining comparison is `isTRUE(ss$mse == 0)`, and the guard verified classed on the exact `Inf`-score input that crashed it at review.
- 2026-08-01: implement pass 3 — F3 closed durably rather than incidentally. Bullets are inline again, so the concrete blindness is gone, but the enumerator now also FAILS on any abort splicing a variable into its message vector (`spliced_message_sites()`), with `R/ci-montecarlo.R`'s runtime `hint` allow-listed as the one deliberate splice D-018 governs. Mutation-verified: rebuilding the classical bullets in a `cause` variable reds both `--check` and `--self-test`, where before it passed both.
- 2026-08-01: implement pass 3 — F4 corrected by `D-020 Amendment 1` (append, never edit): D-020's parenthetical had the bootstrap surviving SSA = 0 but not SE = 0, where the sweep shows it usable on both and failing MSE = 0, and said 'two disjuncts' where there are three. The amendment also records that D-020's enforcement claim outran the code until the splice guard landed. D-020's rule and dispositions are unaffected.
- 2026-08-01: implement pass 3 — F5/F10 NEWS and the sweep script now record that the candidate list is five of seven `ci_method` values, with `mpl` and `posterior` excluded for stated reasons; F8 `art_message()` asserts the SPECIFIC condition class (the classical guard had no class test anywhere in the suite); F9 values print at `signif(, 6)`; F17 checker counts reconciled; F18 the milestone `## Decisions` section now records D-020, its amendment, and the local approach decision; F19 the sweep's runtime note updated for boot_samples 999.
- 2026-08-01: implement pass 3 — F20 carried out to a ROADMAP candidate row (search-first, no existing row): `burch_ci()` raises a RAW unclassed error on SSA = 0 data, a #5/#8 violation the sweep discovered incidentally and no record mentioned. Out of this milestone's scope.
- 2026-08-01: implement pass 3 gate — suite FAIL 0 / PASS 5487 / SKIP 23 (52 in the milestone's own file); `devtools::check()` 0/0/0; `lintr::lint_package()` no lints; `air format --check` clean; `devtools::document()` no diff; every `data-raw` checker passes. The committed sweep TSV is untouched by this pass: pass 3 changed message text and tooling, not measurements.

## Decisions

- 2026-08-01 (D-020, promoted to `cairn/DECISIONS.md`): static remedy text may name a `ci_method` only on swept evidence over the abort's whole trigger class. Promoted rather than kept local because it binds every future abort in the package, not just these four.
- 2026-08-01 (D-020 Amendment 1, promoted): D-020's bootstrap parenthetical was backwards against its own sweep, and its enforcement claim named a guard the enumerator did not yet have. Corrected by amendment because DECISIONS.md is history and is never edited.
- 2026-08-01 (milestone-local): these guards REPORT the quantities that failed and diagnose nothing. Chosen by the maintainer at the review pass-2 gate after two returns in which a described cause was false in a corner; the alternative, completing the case analysis, was rejected as the approach that had already failed twice. The bootstrap guard, which never diagnosed, is the one that drew no truthfulness finding in either pass.

## Review

**Review pass 1 — 2026-08-01.** PR #108. `main` unmoved since the branch was cut
(`git rev-list --count HEAD..origin/main` = 0), so all evidence below is current.

**AC1 — enumeration.** `enumerate-ci-method-remedies.py --check` exits 0: 6
`ci_method`-naming reducer aborts, all classified (1 sweep, 5 fence), committed
enumeration current. Each emitted site carries its file, trigger condition and
named methods (6 `trigger:` and 6 `names:` lines). `grep -c "R/icc.R"` on the
enumeration returns 0, so no pre-dispatch design fence appears. The committed
enumeration is the script's own output, verified by tampering: appending one line
makes `--check` exit 1, restoring it exits 0.

**AC2 — sweep.** `abort-remedy-sweep.tsv` holds 205 rows over 4 sites x 5 methods,
7 geometries (6x3, 10x2, 15x4, 30x3, 12x3, 20x3, 30x2), exact and near-degenerate
triggers, seeds 1-3 at the stochastic site. Outcome vocabulary is exactly
`usable interval | unusable interval | classed abort | raw error | (site not
reached)`; 0 reached rows carry an outcome with no run behind it. Usability is
`boundary_interval_usable()`, the shipped helper. Provenance columns (`r_version`,
`glmmtmb_version`, `platform`, `boot_samples`, `conf_level`) are on every row.

**AC3 — no condemned method named.** Mechanical cross-check of the live
enumeration against the sweep: for every method a shipped site still names, the
sweep's failure count at that site is 0 or the site is a fence never swept.
Violations: none. The one swept site still naming a method
(`R/ci-npbootstrap.R:01b75d1a61`, `montecarlo`) has 0 failures over 9 datasets;
the three condemned sites name nothing and have left the enumeration.

**AC4 — class and leading line unchanged, still actionable.** The `main..HEAD`
diff of the three files touches no `class = "..."` line and no leading message
line. Rendered live, each abort keeps its opening sentence and its diagnostic
bullet, and closes on an imperative the user can act on ("Inspect the ratings:
every rater gave each subject the same score").

**AC5 — pinned and mutation-verified, re-run at review.** Baseline
`test-abort-remedy-truthfulness.R` 23 pass / 0 fail. Restoring each pre-milestone
bullet reds the pin: bootstrap 2 failures, classical 2, npbootstrap 3; stripping
the deliberately KEPT `montecarlo` bullet reds 1. Restored to 23/0, and
`git diff --quiet R/` confirms the tree is clean after the probes. Assertions are
on the property (`art_named_methods()`), not the sentence, and every abort is
fired at its reducer — stub `simulate_refit` for the bootstrap guard, raw
degenerate frames elsewhere — never through `icc()`.

**AC6 — records.** `NEWS.md` gains the user-visible bullet (15 added lines, 0
milestone-number leaks). `cairn/DECISIONS.md:683` carries D-020, which references
D-018 (5x), D-019 (2x), D-012 and D-013 (1x each) and states its relation to each.

**AC7 — toolchain gate.** `devtools::check(env_vars = c(NOT_CRAN = "false"))`
Status OK — 0 errors, 0 warnings, 0 notes. Suite at `NOT_CRAN=true CI=true`
FAIL 0 / PASS 5458 / SKIP 23. `devtools::document()` no diff; `pkgdown::check_pkgdown()`
"No problems found"; `README.md` untouched by the branch; `air format --check` clean;
`lintr::lint_package()` no lints; all six `data-raw` checkers pass.

**Universal cairn checks.** `cairn_validate` exit 0 — 16 PASS including
`coverage complete`, `weight caps`, `mirror agreement`, `binding criteria`,
`principles slot valid`; 7 advisory OK; 1 WARN (`dangling id tokens`, 321,
pre-existing pre-migration ids). No `DESIGN.md` principle changed, so
`cairn_impact` does not apply.

**GATE FAILURE — returned to `in-progress` (review pass 1).** Three fresh-context
lenses ran. [S] blame-history: 0 findings — it established that the three removed
bullets originated as boilerplate in ordinary feature commits (`b63c471c`,
`b7ca3f58`, `a37ef90e`), never as text a milestone deliberately decided, so
removing them corrects an unverified claim rather than undoing considered work.
[S] prior-review: 0 findings; the GitHub inline-comment surface probed empty, and
the M93/M97/M98/M99 archives show this diff respecting each lesson it inherits.
[O] diff-bug: 28 findings, 9 scoring >= 80.

**The two that fail the gate.** The milestone's own defect class survives in the
text it shipped:

- **A1 (93)** — `npbootstrap_ci()`'s observed-data guard is
  `!is.finite(obs$logf) || obs$se_ij_logf == 0`, and the second disjunct fires on
  healthy data. Reproduced at review: subject means -1/0/1 and within-subject
  ranges 1/0/1 give a finite `log F` = 1.79 and `se_ij_logf` = 0, so the abort
  fires and the new bullet's "either every subject has the same mean score, or
  every rater agreed exactly within each subject" is false on BOTH disjuncts. The
  rewrite claimed to state only what the guard establishes and mis-read the guard.
  The sweep never generated this branch (`gen_mse0`/`gen_ssa0` only).
- **A2 (90)** — `bootstrap_ci()`'s guard fires on a refit-convergence count with
  many causes; the new bullet asserts one ("subjects scored identically by every
  rater"), which the milestone's OWN sweep contradicts on its `MSE=0 near` cells
  (jitter SD 1e-8, subjects not identical). It also misdescribes the mechanism:
  the parametric bootstrap simulates from the fitted model rather than resampling
  ratings.

**Actioned, evidence-quality (>= 80).** B5 (92) the enumeration's `class` column
reads `(default)` for 5 of 6 sites because `CLASS_RE` looks for a literal
`class =` that `abort_unsupported()` sets inside the wrapper. C5 (94) every sweep
row's `generator` provenance reads the literal `cell$gen`
(`deparse(substitute())` inside a loop), so no row traces to its generator. C7
(92) the sweep's header claims its sites are the ledger's `sweep` rows while three
of its four hardcoded keys no longer exist there, and `names = "montecarlo"` is
hardcoded at all four. C2 (82) `fire()` skips the point fit while `run_remedy()`
goes through `icc()`, so cells are counted "reached" whose message no user could
see — the classical verdict is 0/3 not 0/4 and npbootstrap-observed 0/7 not 0/8;
the conclusion survives, the counts in the work log and D-020 do not. C3 (80) the
sweep measures at `boot_samples = 99` against a shipped default of 999,
contradicting the M97 lesson quoted in `R/boundary-hint.R`. B1 (82) the
enumerator's `_slice_call` balances parens over comment text, so an unmatched `(`
in a comment merges the following abort into one site that inherits the first's
ledger row — and this milestone added prose comments inside three abort calls.
E4 (82) the NEWS bullet inherits A1's error.

**Logged below threshold (19, not actioned).** A4 78 the classical bullet is
entailed only by the `mse == 0` disjunct · D1 76 `art_message()` asserts only the
parent `intraclass_error`, so AC4's class requirement is not pinned · C4 72 the
bootstrap site is swept at one seed though its refits are stochastic · E5 68 the
milestone says three/four/five `data-raw` checkers in three places · A5 66 the
regex pins one spelling of a method name · D2 66 both leading-line assertions
share a substring · E3 63 D-019 and D-020 read D-018's reach differently · B7 62
ledger keys churn on a pure refactor · B2 58 `"i" = ` bullets are invisible ·
C6 55 hardcoded `divisor = 2`, currently inert · E1 55 D-020's rule reads as
universal while five `fence` sites name a method unswept · B3 52 one method
spelling · C1 50 the two npbootstrap sites are indistinguishable to `reached` ·
A3 40 the KEPT bullet's "use a larger design" half is wrong at 30 subjects
(pre-existing text, out of scope here) · D3 32 dead stub parameter · E2 32 the
specific fence reproduction did not reproduce · B6 28 AC1's stated predicate vs
the implemented one · B4 22 the `(unguarded)` fallback is honest, not false ·
D4 22 a strict pin behaving strictly.

Acceptance checkboxes are unticked despite the AC1-AC7 evidence above: the next
pass re-verifies from scratch rather than inheriting this pass's evidence.

**Review pass 2 — 2026-08-01.** PR #108, head `f3f1a8a`. `main` still unmoved.

**AC1 — enumeration.** `--check` exits 0: 6 sites, all classified (1 sweep, 5
fence), committed enumeration current; tampering with it exits 1. `--self-test`
passes, now including two synthetic `_slice_call` probes (an unmatched paren in a
comment; a string continuation carrying `(#5)`) and a probe that no site reports
class `(default)`. `grep -c "R/icc.R"` on the enumeration = 0.

**AC2 — sweep.** 210 rows over 4 sites x 5 methods, four named generators
(`gen_mse0`, `gen_ssa0`, `gen_se_zero`, `gen_resample_degenerate` — the third
added because review A1 showed the SE-zero branch had never been swept), all at
the shipped `boot_samples = 999`. 0 reached rows carry an outcome with no run.
`point_fit_ok` is recorded and gates `reached`, excluding 6 cells whose glmmTMB
point fit dies before any CI-stage guard — data on which no user could meet the
message.

**AC3 — no condemned method named.** Mechanical cross-check of the live
enumeration against the corrected sweep: violations none. The only swept site
still naming a method is the degenerate-resample guard, `montecarlo`, 0 failures
over 9 datasets.

**AC4 — class and leading line unchanged.** Byte-compared across `main..HEAD`:
the leading message line and every `class =` argument are IDENTICAL in all three
files (the classical file's diff shows the leading line moving position inside the
restructured call, not changing). Each message still closes on an imperative.

**AC5 — pinned and mutation-verified, re-run at review.** 45 assertions, up from
23. Restoring pass 1's false npbootstrap branch reds 6; restoring its false
bootstrap cause reds 2; baseline and restored both 45/0, tree clean afterwards.

**AC6 — records.** `NEWS.md` carries the corrected bullets (0 milestone-number
leaks); `cairn/DECISIONS.md:683` carries D-020.

**AC7 — toolchain gate.** `devtools::check(env_vars = c(NOT_CRAN = "false"))`
0 errors / 0 warnings / 0 notes. Suite `NOT_CRAN=true CI=true` FAIL 0 / PASS 5480
/ SKIP 23. `lintr::lint_package()` no lints; `air format --check` clean; all five
`data-raw` checkers pass. `cairn_validate` 16 PASS / 0 FAIL.

**Independent review — three fresh lenses.** [S] prior-review verified each of
pass 1's nine actioned findings against the current code rather than the work log,
and reported all nine genuinely fixed with no sub-threshold finding made worse.
[S] blame-history: 0 findings — it confirmed the `se_ij_logf == 0` disjunct dates
to M75 with a loose comment that conflated it with variance degeneracy, so the
rewrite corrects an imprecision standing since then; that the M97 999-vs-reduced
lesson says what the sweep now cites; and that D-020 contradicts none of
D-012/D-013/D-018/D-019.

**GATE FAILURE — returned to `in-progress` (review pass 2, SECOND return).**
[S] prior-review and [S] blame-history both reported 0 findings; the [O] diff-bug
lens reported 20, of which 3 score >= 80. Two were reproduced independently at
the gate before being recorded.

- **F1 (96) — a crash this milestone introduced.** `R/ci-classical.R`'s new branch
  selector `cause <- if (ss$mse == 0)` evaluates `if (NA)` when MSE is NaN, so the
  guard dies with an unclassed `simpleError` ("missing value where TRUE/FALSE
  needed") where `main` raised a classed `intraclass_singular_fit`. Reproduced at
  the gate through `searle_ci()` on a frame carrying one `Inf` score. Violates #5
  and #8, and AC4's class-preservation directly. `burch_ci()` shares the guard.
  The one-character fix is `isTRUE(ss$mse == 0)`.
- **F3 (92) — the completeness gate is blind at the sites this milestone
  repaired, and three durable records say otherwise.** Moving the bullets out of
  the abort call into a `cause <- if (...)` variable put them outside
  `_slice_call`'s slice. Reproduced at the gate: re-adding
  `ci_method = "montecarlo"` to the classical `cause` block leaves BOTH `--check`
  and `--self-test` at rc 0, while the R test file catches it. So the property is
  defended, but the ledger header ("it reappears here UNCLASSIFIED and `--check`
  fails"), the self-test comment, and D-020's citation of the enumerator as the
  enforcement mechanism are each false for 2 of the 3 de-named sites.
- **F2 (80) — the A1 defect surviving inside the A1 repair.**
  `mse_zero <- is.nan(obs$logf) || identical(obs$logf, Inf)` conflates 0/0 (a real
  zero MSE) with Inf/Inf (overflow), so on healthy-but-overflowing data the
  message asserts "Within-subject variance is exactly zero ... every rater gave
  each subject the same score" — false. The classical sibling repaired under A4
  does carry an overflow branch, so the two guards now disagree about what NaN
  means. Reducer-reachable only today; `icc()` dies in the point fit first.

**Logged below threshold (17).** F4 78 D-020's parenthetical ("the parametric
bootstrap survives SSA = 0 but not SE = 0") is backwards against its own committed
sweep, which shows bootstrap usable on SSA = 0 (4/4) and SE = 0 (1/1) and failing
MSE = 0 (0/3), and says "two disjuncts" where there are now three · F8 75 AC4's
class requirement is still unpinned for the classical guard · F7 65 the classical
`else` branch is unreachable via `icc()` and untested · F5 65 NEWS says "every
interval method the package ships" for a sweep covering five of seven · F20 55 the
sweep incidentally recorded `burch` raising a RAW unclassed error on all four
SSA = 0 cells, a #5/#8 violation no record mentions · F6 30 `npb_groups()`
documents a non-finite fence `anyNA()` does not implement · F11 30 `named_now`'s
lookbehinds fail silently · F15 30 two form-pins in a property-pin file · F9 25 a
15-digit log F in user-facing text · F16 25, F13 20, F10 20, F17 20, F12 15,
F18 15, F19 15.

**Thrash trigger (b) FIRES.** AC4 has now failed twice, each time by a new
mechanism of the same shape: a message asserting a fact about the user's data that
is false in a corner (pass 1 A1/A2 — the wrong degeneracy and a single invented
cause; pass 2 F2 — NaN conflated with overflow). Trigger (a) has NOT fired: this
is the second return, not the third. The rulebook's remedy for (b) is to
reconsider the alternative the plan gate recorded against, and the gate recorded
none for this question — its four recorded alternatives concern which sites to
cover, the evidence bar, static-vs-runtime method naming, and where the checker
lives. None covers how a message should describe a cause. So the disposition goes
to the maintainer with an escalation offer, per (b) and D-004.

Every acceptance box unticked; the next pass re-verifies from scratch.
