# M100: Measure which abort remedies are untruthful, and gate the enumeration

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** RR04
- **Principles touched:** GP1, GP6, GP7
- **Branch/PR:** `m100-abort-remedy-truthfulness` · https://github.com/jmgirard/intraclass/pull/108

## Goal

Measure which `ci_method` names the CI-reducer degeneracy aborts offer are
untruthful, and gate the enumeration of sites that make such a claim.

## Scope

**In:** the enumerator (`data-raw/enumerate-ci-method-remedies.py`), its committed
enumeration and classification ledger, the seeded sweep
(`data-raw/sweep-abort-remedies.R`) with its committed results, and the accuracy
of the records describing all of them. Evidence and tooling only.

**Out:** every message change and the rule governing what a message may assert →
**M101**, so no rule sits on `main` while the code breaks it (re-cut gate
2026-08-01; rationale in the work log). The claims ledger, its checker and the CI
wiring RR04 asks for → a successor milestone (RR04 BC2/BC3/BC6; ingest audit
2026-08-02).

## Acceptance criteria

- [ ] AC1 A committed script enumerates the aborts under `R/ci-*.R` matching its
      stated predicate, emitting per site the file, the triggering condition and
      the `ci_method` string(s) its remedy bullets name; the committed enumeration
      is that script's own output; a committed ledger classifies every emitted
      site; and `--check` exits non-zero on an unclassified site, on a ledger row
      matching no site, and on a stale committed enumeration. Each of those three
      failure modes is demonstrated by a self-test probe that reds when that
      failure is introduced. The enumeration contains at least the four guards
      this milestone measured — `bootstrap_ci()`'s refit-convergence guard,
      `classical_guard_observed()`, and `npbootstrap_ci()`'s observed-data and
      degenerate-resample guards — identified by their guarding conditions, so a
      predicate that matched nothing could not satisfy this criterion.
- [ ] AC2 (BC1): The ledger header, the enumerator docstring, and the milestone's
      live limits record each state exactly the probe-demonstrated limit set: six
      predicate shapes (L1-L6) and five unreported splice shapes, with the
      `R/ci-*.R` file scope stated as a limit explicitly not demonstrated by a
      probe. `--self-test` contains an assertion tying the stated count to
      `len(_limit_shapes())` by PARSING the ledger header and the docstring, so a
      divergence between record and probe list exits non-zero. A record frozen
      under IP4 satisfies this by carrying an appended dated supersession note.
      Tolerance: exact counts.
- [ ] AC3 For each site the ledger marks `sweep`, a committed seeded script
      records, across several geometries of that site's trigger condition and at
      the shipped `boot_samples` default, whether each swept `ci_method` returns a
      usable interval on data that reached the abort, judged by the shipped
      `boundary_interval_usable()`. Reaching the abort is confirmed by catching
      its own classed condition from the reducer called directly. The swept
      candidate set is named in the script with a stated reason for every
      `ci_method` value excluded. A cell whose point fit fails before the guard is
      excluded from the denominator and recorded as excluded.
- [ ] AC4 (BC5): AC4 is evaluated as: `git diff main..HEAD --name-only` lists no
      path under `R/` and neither `NEWS.md` nor `cairn/DECISIONS.md`; and no
      *live* record statement — one not followed by a dated supersession note —
      purports to bind conduct beyond this milestone. With BC4's entry appended,
      both clauses hold.
- [ ] AC5 (BC4): The milestone `## Decisions` section carries an appended, dated
      supersession entry stating that D-020 and its amendment exist nowhere in
      `cairn/DECISIONS.md` on this branch (`grep -c 'D-020' cairn/DECISIONS.md`
      = 0), never reached `main`, and are re-authored by M101; and that the two
      rule statements in prior entries bind nothing on this branch. No existing
      line in that section is modified: `git diff` for the fix commit shows only
      additions within it.
- [ ] AC6 The profile `verify` slot is clean, plus the fuller pre-review check it
      names, with every `data-raw` checker run locally.
- [ ] AC7 (BC7): The sweep script header states, per swept site, which disjuncts
      of the trigger condition the grid generates and which it does not — at
      minimum that the classical guard's `!is.finite(f)` disjunct (MSA overflow,
      MSE finite non-zero) and bootstrap refit-failure triggers other than
      MSE=0-degenerate data are not generated — and no header sentence claims
      coverage of a whole trigger class. The committed sweep TSV is unchanged:
      `git diff 12cba54..HEAD -- data-raw/abort-remedy-sweep.tsv` is empty.
- [ ] AC8 (BC8): Each work-log figure a review proved wrong (the "reds 7" clause;
      "all five `data-raw` checkers"; the 80/30/50 unit slips) is superseded by an
      appended CORRECTION line citing a committed probe or a command over a
      committed artifact; the reproducing half of the "narrowing the glob reds 5"
      clause is preserved as stated. Original lines unedited.
- [ ] AC9 (BC9): The enumerator docstring makes no requirement claim about M101
      that M101's milestone file does not contain: the docstring's "is required
      to" clause is replaced by the mechanical fact (a changed leading line
      re-keys the site and `--check` fails until the ledger row is renewed).
      `check()`'s docstring states four failure routes and attributes the splice
      route's probes to `_unreported_splices()`.
- [ ] AC10 (BC10): The ROADMAP runtime-hint row's "all nine resample-guard
      datasets" clause carries its own reproducing command over the committed
      sweep TSV, yielding nine `usable interval` lines. Tolerance: exact.

### Deviations from RR04

| BC | Departure | Ground (ingest audit, fresh context, 2026-08-02) |
|---|---|---|
| BC1 | struck the "or a seventh self-test probe" disjunct; parity assertion must PARSE the record surfaces; frozen records satisfy by supersession note | the struck disjunct makes the records say seven probed limits while `len(_limit_shapes())` stays six, reinstating the finding it closes; a bare `assert len(...) == 6` ties a literal to the code, not the record to the probe list; the live limits record is IP4-frozen and otherwise unreachable |
| BC2 | deferred to a successor milestone | its first clause ("every figure the post-re-cut records state about ...") is an unbounded universal over a domain no procedure it names enumerates — the defect that sank AC5 — and RR04 §3 itself forbids building the detector that would bound it |
| BC3 | deferred with BC2 | jointly unsatisfiable with BC8 (one mandates preserving a figure the other bans) and with retained AC6 (whose gate figures fall outside BC2's ledger domain and cannot be cheaply recomputed); enforceable only once BC2's ledger exists |
| BC6 | deferred with BC2 | certifies "cannot reach a release" as true of a lint-job wiring that only reds CI, and the wiring is the same deliverable as the checker it would run |
| BC7 | `<fix-base>` bound to `12cba54` | the placeholder is not a runnable command, and `main..HEAD` is the wrong base, the TSV being new on this branch |
| BC9 | struck disjunct 1 ("either M101 gains the leading-line-stability criterion") | places satisfaction of an M100 criterion inside another milestone's plan-owned body, and keeping the docstring clause violates BC5 |
| BC10 | inlined the command's description rather than its literal text | the criterion's example carries literal tabs inside backticks that do not survive into this file; T11 records the exact command |

## Coverage

- AC1 → T2, T3
- AC2 → T7
- AC3 → T4
- AC4 → T1, T8
- AC5 → T8
- AC6 → T12
- AC7 → T9
- AC8 → T10
- AC9 → T11
- AC10 → T11

## Tasks

Pass-4 scope, complete; detail in the work log.

- [x] T1 Strip the branch to tooling and evidence; revert `R/`, `NEWS.md`, `cairn/DECISIONS.md`.
- [x] T2 Anchor the enumerator on the four measured guards, keyed on their conditions.
- [x] T3 Probe the three `--check` failure modes and each stated predicate limit.
- [x] T4 Re-run the sweep; confirm each reach by the site's own classed condition.
- [x] T5 Add the recompute/locate command beside every factual claim, and run each.
- [x] T6 Gate: suite, `devtools::check()`, `lintr`, `air`, every `data-raw` checker.

RR04 ingestion, pass 5.

- [x] T7 Repair the limits records: state the six probed predicate shapes and the
      five probed splice shapes, mark file scope as a limit with no probe, and add
      the parsing parity assertion to `--self-test`.
- [x] T8 Append the dated supersession entry to `## Decisions` covering D-020's
      absence and the two rule statements; re-verify the git-diff clause.
- [x] T9 Rewrite the sweep header to state generated vs ungenerated disjuncts per
      swept site, with no whole-class claim; confirm the TSV byte-unchanged.
- [x] T10 Append CORRECTION lines for the "reds 7", "all five checkers" and
      rows-vs-cells figures, preserving the reproducing half of each line.
- [ ] T11 Fix the two docstring claims (the M101 requirement, `check()`'s route
      count) and add the ROADMAP row's second recompute command.
- [ ] T12 Gate: full suite at `NOT_CRAN=true CI=true`, `devtools::check()`,
      `lintr::lint_package()`, `air format --check`, every `data-raw` checker.

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

- 2026-08-01: review pass 3 FAILED the gate — THIRD return, thrash trigger (a) fires and (b) fires for the third consecutive pass. Two gate-reproduced findings of the milestone's own defect class: the classical message states a requirement the guard does not test (MSA can be the non-finite one, MSE finite and non-zero), and the splice guard catches one splice shape while three records claim it catches any (`i = cause` passes both gates). Plus six findings against this milestone's own records, including a false claim about its own review history and an error inside D-020 Amendment 1's correction. [S] prior-review 0 findings and confirmed passes 1-2 fully fixed. Per the thrash rule this is NOT queued for a fourth implement pass; it routes to /milestone-plan for a re-cut. Status -> in-progress.

- 2026-08-01: RE-CUT by /milestone-plan after the third review return. M100 keeps measurement and tooling only and ships nothing user-facing; every message change and the rule governing them move to M101. Gate decisions: the first milestone ships no message changes at all, because a deletion-only diff would leave on `main` the two diagnostic bullets this milestone's own review proved false, under a NEWS entry about truthfulness (re-cut audit; #5/#8); the rule lands with the messages it governs; and D-020 plus its amendment, neither of which has reached `main`, are removed from this branch and re-authored as one correct entry in M101. Tasks re-cut to T1-T6; every acceptance box unticked -- the criteria changed, so each re-verifies from scratch. The prior tasks are superseded but their work stays on the branch.
- 2026-08-01: re-cut criteria audit ([O], fresh context) returned three gaps, all fixed before the file was written: an unanchored enumeration predicate (AC1 now names the four measured guards by their conditions, so a predicate matching nothing cannot satisfy it), a recompute rule scoped only to sweep numbers (AC5 now covers counts, ledger keys and this milestone's own review-history claims, which is where most of pass 3's record errors were), and the three `--check` failure modes being hand-mutated rather than probed (T3).

- 2026-08-01: implement gate (re-cut) chose deleting `tests/testthat/test-abort-remedy-truthfulness.R` outright over retargeting its fixtures at main's messages, because every one of its assertions pins text T1 reverts and M101 AC3 authors the per-guard fixtures and tests; falsified by a message property this milestone owns that no other test covers.
- 2026-08-01: implement gate (re-cut) chose applying AC5's recompute rule to records written from the re-cut forward, plus one work-log line correcting the specific pre-re-cut figures a later review proved false, over retrofitting commands into every historical line, which IP4 forbids editing.
- 2026-08-01: T1 — branch stripped to tooling and evidence. `R/`, `NEWS.md` and `cairn/DECISIONS.md` reverted to `main`; `tests/testthat/test-abort-remedy-truthfulness.R` deleted (52 assertions, all pinning reverted text). Locate: `git diff main..HEAD --name-only`, which must list no `R/` path and neither of the two files (AC4).
- 2026-08-01: T1 — with main's messages back, three sites name `ci_method` again, so the ledger regains their rows and the enumeration is 9 sites, 4 `sweep` + 5 `fence`. The `sweep` rows are dispositions only: this milestone records what the sweep measured, never what a bullet should say. Recompute: `python3 data-raw/enumerate-ci-method-remedies.py --check`.
- 2026-08-01: CORRECTION, superseding the pre-re-cut work-log lines that stated enumeration counts and de-naming outcomes. Every "6 sites (1 sweep, 5 fence)" figure, and every claim that three bullets name no method or that their ledger rows were removed, described the branch's now-reverted `R/` and is false of the tree from T1 on. The current figures come from `python3 data-raw/enumerate-ci-method-remedies.py --check`. The pass-3 review also proved two specific record claims false and neither is repeated here: the `## Decisions` line saying the bootstrap guard "drew no truthfulness finding in either pass" (pass 1's A2 is one, scored 90), and D-020 Amendment 1's "three disjuncts, not two" for a guard with two disjuncts and three causes — locate both with `grep -n "drew no truthfulness\|three disjuncts" cairn/milestones/M100-abort-remedy-truthfulness.md`. Those lines are history and stay unedited (IP4).

- 2026-08-01: T2 — the four swept guards are anchored in `--self-test` on fragments of their own `if (...)` conditions (`n_ok < min_frac`, `ss$mse == 0`, `se_ij_logf == 0`, `n_bad > 0`), so a predicate that stopped matching one could not leave it unswept with `--check` still printing OK. Mutation-verified: narrowing the file glob to `R/ci-n*.R` reds 5 assertions naming the two dropped guards, and breaking `BULLET_RE` reds 7. Recompute: `python3 data-raw/enumerate-ci-method-remedies.py --self-test`.

- 2026-08-01: T3 — `check()` and the two scanners now take their inputs as parameters, so `--self-test` DRIVES the three `--check` failure modes on constructed input and reads the exit code, against a passing control. Mutation-verified one gate at a time: removing the missing-row branch, the stale-row branch and the freshness branch each reds exactly its own probe.
- 2026-08-01: T3 self-caught, and the reason the probes were worth building: the unclassified-site probe first passed for the WRONG reason — its `committed` text did not match its own input, so it was failing on freshness, and deleting the missing-row branch left it green. Fixed by rendering `committed` from the same input; the mutation then reds. A second probe caught an overstatement in the same pass: a whole message vector spliced on its own line IS reported, so the limit was narrowed to the shape that actually escapes, the vector spliced on the call's own line.
- 2026-08-01: T3 — the predicate's limits L1-L6 plus file scope are stated in the script docstring, the ledger header and the `## Decisions` section below, each with a probe that constructs the shape and shows it unmatched. Mutation-verified: widening the method matcher to accept single quotes reds L1's probe, and widening the splice reporter to see `i = cause` reds that splice limit — a limit closed reds its own probe rather than leaving a record overstating the gate. Recompute: `python3 data-raw/enumerate-ci-method-remedies.py --self-test`.

- 2026-08-01: T4 — the sweep re-run against `main`'s messages, 210 rows, 26 cells reached. `montecarlo` usable on 0/6 at the bootstrap refit-convergence guard, 0/3 at classical MSE = 0, 1/8 at npbootstrap observed-degeneracy and 9/9 at the resample guard; `bootstrap` reaches 5/8 at the third. Recompute: `Rscript data-raw/sweep-abort-remedies.R` (~25 min), or read the committed run with `sed -n '/---- per site/,$p'` over its stdout.
- 2026-08-01: T4 — reach is now confirmed by the site's OWN message, not only its condition class. Both npbootstrap guards raise `intraclass_singular_fit` from the same reducer, so class alone could not tell them apart and a cell aimed at one could have been recorded as evidence about the other (pass-1 finding C1, scored 50). The identity fragments are derived from the committed enumeration's leading lines — the same strings the ledger keys hash — with glue spans cut out and ALL remaining static text required, because " interval is undefined for this data." alone is shared by two sites. Verified diagonal on live conditions: each site's fragments match its own condition and neither of the others.
- 2026-08-01: T4 — the confirmation reclassified NOTHING on this grid: `grep -c 'another guard in the same reducer' data-raw/abort-remedy-sweep.tsv` = 0, and the per-site reach counts are identical to the pre-confirmation run. It is a guard against a future grid or a future message edit, not a correction to these numbers. The 80 unreached rows split 30 point-fit failures and 50 cells where the reducer returned an interval; no unreached row carries an outcome with a run behind it.
- 2026-08-01: T4 — the candidate set stays five of the seven `ci_method` values with the exclusions stated in the script (`mpl` fenced to the balanced two-way random cell and aborting `intraclass_unsupported` on every one-way dataset here; `posterior` needing the brms engine these fits do not use). Locate: `grep -n 'Five of the seven' -A 4 data-raw/sweep-abort-remedies.R`.
- 2026-08-01: T4 — the first re-run died after writing its results with `object 'ion' not found`, because `air format` reformatted the script WHILE `Rscript` was still reading it: `Rscript` consumes a file expression by expression, so an edit mid-run shifts the offsets it has yet to read. Results discarded rather than trusted and the sweep re-run on a frozen script (`md5` identical before and after, exit 0), which reproduced every verdict.

- 2026-08-01: T5 — every command this milestone's post-re-cut records cite was RUN, and two of them faulted the records rather than confirming them, which is the whole point of the criterion. (i) `grep -c 'another guard in the same reducer' ...` exits 1 when the count is 0, so a true claim was cited by a command that reports failure; restated as `awk '/another guard in the same reducer/' data-raw/abort-remedy-sweep.tsv | wc -l`, which prints 0 and exits 0. (ii) the CORRECTION line above says its grep locates D-020 Amendment 1's error; the grep locates the milestone-local `## Decisions` claim and the review's record of that error, but NOT the amendment text, which T1 removed from this branch with the rest of `cairn/DECISIONS.md` and which never reached `main` — `git diff main..HEAD -- cairn/DECISIONS.md` prints nothing. M101 re-authors D-020 and its amendment as one correct entry. The line stands as written (IP4); this supersedes its locate clause.
- 2026-08-01: T5 — the two ROADMAP candidate rows that cite this milestone's sweep were re-verified against the clean re-run and each now carries the command that recomputes it: `burch` raises a raw unclassed error on all four SSA = 0 exact cells at `bf1a802a9c`, and the `gen_se_zero` cell has `montecarlo`, `searle`, `burch` and `bootstrap` all returning usable intervals with `npbootstrap` aborting classed. Both hold on the committed TSV.
- 2026-08-01: T5 — commands run clean at this point: `git diff main..HEAD --name-only` (7 paths, none under `R/`, neither `NEWS.md` nor `cairn/DECISIONS.md`, so AC4 holds), `--check` (9 sites, 4 sweep + 5 fence), `--self-test`, the candidate-set locate, and the two sweep queries above.

- 2026-08-01: T6 gate clean — suite `NOT_CRAN=true CI=true` FAIL 0 / PASS 5435 / SKIP 23 (identical to `main`'s baseline, since this milestone adds no R test and T1 removed the one the branch had); `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes in 2m49s; `lintr::lint_package()` 0 lints; `air format --check .` clean; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; all five `data-raw` checkers pass plus `enumerate-ci-method-remedies.py --check` and `--self-test`; `cairn_validate` all checks passed, 321 pre-existing dangling-id advisories. Status -> review.

- 2026-08-01: CI green on `6a8d51c` — all nine checks pass (format-check, check-references, lint, pkgdown, test-coverage, codecov patch + project, ubuntu-latest and windows-latest release). Recompute: `gh pr checks 108`.

- 2026-08-01: review pass 4 FAILED the gate — FOURTH return. [O] diff-bug returned 20 findings, 8 scoring >= 80; both [S] lenses effectively 0 (prior-review confirmed passes 1-3 fixed; blame-history's single finding scored 25). The tooling verified CORRECT — two sweep cells re-run end-to-end byte-matched their committed rows — and the defect class migrated entirely into the records about it: AC2 fails (two records claim a probe for a seventh limit where six exist), AC5 fails four ways (a mutation count no reading reproduces, a wrong checker count, a rows/cells unit slip, and claims with no reproducing command), AC4 fails its `states no rule` clause (the live `## Decisions` section states D-020's rule while the reverted tree breaks it), and O2 (90) says D-020 was promoted to `cairn/DECISIONS.md` where `grep -c 'D-020' cairn/DECISIONS.md` = 0. Thrash trigger (a) fires on the fourth return with a re-cut already spent, so the disposition goes to the maintainer rather than to a fifth pass. Status -> in-progress.

- 2026-08-01: pass-4 gate disposition, maintainer's choice: ESCALATE for an independent review rather than a fifth fix pass, a park, or a drop. The question to be settled is not which claims are wrong — those are enumerated and individually small — but what structure would stop a milestone whose records have overclaimed in four consecutive passes, twice inside the very text written to correct the previous overclaim. Status stays `in-progress`; no work proceeds until the review returns.

- 2026-08-01: blocked on RB04 (why this milestone's records keep overclaiming, and what would stop it). Committed to the milestone BRANCH rather than the default branch, a logged deviation from the skill's docs-only-on-main step: M100's tracking state — its status mirror, work log and review sections — lives on the branch with an open PR, and splitting the brief from it would put the milestone's own record in two places.

- 2026-08-02: ingested RR04 (split, with named departures — maintainer's choice at the ingest gate). `Driving RR:` set; AC2 and AC5 retired as superseded and replaced by RR04's BC1 (repaired) and BC4/BC5/BC7/BC8/BC9/BC10; BC2/BC3/BC6 deferred to a ROADMAP candidate row. Tasks T7-T12 added. The plan-owned body needed two compressions to fit the 149-line cap (Scope's re-cut narrative, then the completed tasks' detail — both now carried by the work log), and `cairn_validate` still WARNs two split tripwires at 10 criteria and 12 tasks: the size concern the ingest audit raised is real and unresolved. RR04's BC list was normalized to the canonical `- BC<n>:` form so the `binding criteria` check could parse it; it now PASSes.

- 2026-08-02: T7 — the limits records now state six PROBED predicate shapes and five PROBED splice shapes, with file scope stated as the one limit no probe demonstrates, in all three surfaces (script docstring, ledger header, an appended `## Decisions` note superseding the frozen entry). Both machine-readable surfaces carry one canonical `PROBED LIMITS:` line that `--self-test` PARSES and binds to `len(_limit_shapes())` / `len(_unreported_splices())`. Mutation-verified: stating seven in the ledger reds it, deleting the docstring line reds it, and adding a sixth splice probe reds BOTH records; all restored green, tree clean. Recompute: `python3 data-raw/enumerate-ci-method-remedies.py --self-test`.

- 2026-08-02: T8 — the `## Decisions` section now carries a dated note recording that D-020 and its amendment are absent from `cairn/DECISIONS.md` on this branch, never reached `main`, and are M101 T2's to re-author, and that the two rule statements in the frozen entries bind nothing here. Re-verified at this commit: `grep -c 'D-020' cairn/DECISIONS.md` = 0, `git diff main..HEAD -- cairn/DECISIONS.md` empty, `git diff main..HEAD -- R/` empty, and `git diff main..HEAD --name-only` lists 9 paths — none under `R/`, and neither `NEWS.md` nor `cairn/DECISIONS.md` (AC4's first clause). The fix commit's diff inside `## Decisions` is additions only.

- 2026-08-02: T9 — the sweep header states, per swept site, which disjuncts of the trigger condition the grid generates and which it does not (the classical guard's `!is.finite(f)` disjunct with MSE finite and non-zero, and every bootstrap refit-failure route other than MSE=0-degenerate data, both named as NOT GENERATED), plus the grid-wide limit that it is balanced one-way data only. The "must hold across the whole class" sentence is gone, and so is the candidate comment's rule about what a remedy may name — a rule statement binding beyond this milestone, which is M101's (AC4). Self-caught while writing it: the first draft attributed `log F = -Inf` to `gen_mse0`; measured on a 6x3 exact cell, `gen_mse0` gives `+Inf` and `gen_ssa0` `-Inf`, and the header records the measured values. The committed TSV is byte-unchanged: `git diff 12cba54..HEAD -- data-raw/abort-remedy-sweep.tsv` is empty.

- 2026-08-02: T10 CORRECTION superseding the 2026-08-01 T2 line's mutation figures. "breaking `BULLET_RE` reds 7" is not reproducible and its cited `Recompute: --self-test` never reproduced it — a red-count is a property of a mutation, not of the tree, so the mutation must be named. Named and re-measured at `fceac5c`: replacing `BULLET_RE` with a pattern that never matches (`^\s*i BROKEN = `) reds 8 assertions, counted as `python3 data-raw/enumerate-ci-method-remedies.py --self-test 2>&1 | grep -c 'SELF-TEST FAIL'`, against 0 on the restored tree. The line's other half REPRODUCES as stated: narrowing `R_GLOB` to `R/ci-n*.R` reds 5 by the same command. Both mutations restored, tree clean (`git diff --stat data-raw/enumerate-ci-method-remedies.py` empty).
- 2026-08-02: T10 CORRECTION superseding every "all five `data-raw` checkers pass" figure (the 2026-08-01 T6 gate line and the pre-re-cut T5/T6 lines): five checkers exist in `data-raw/` in total, of which FOUR are other milestones' and the fifth is this milestone's own, so "all five plus `enumerate-ci-method-remedies.py`" counts this one twice. Recompute: `ls data-raw/check-*.py data-raw/enumerate-*.py` — five paths, of which `enumerate-ci-method-remedies.py` is M100's. Three of the five are wired into CI (`grep -c 'run: python3 data-raw' .github/workflows/lint.yaml` = 6, two invocations each of `check-reference-observations.py`, `enumerate-generalizing-claims.py` and `check-mpl-doc-claims.py`); `check-oracle-registry.py` and this milestone's checker are run locally only, which is RR04's enforcement finding.
- 2026-08-02: T10 CORRECTION superseding the 2026-08-01 T4 line's "The 80 unreached rows split 30 point-fit failures and 50 cells": all three figures are ROW counts and the last is labelled cells. In cells the split is 6 and 10. Recompute over the committed TSV: `awk -F'\t' 'NR>1 && $8!="TRUE" {r++; if ($9=="FALSE") p++} END {print r, p, r-p}' data-raw/abort-remedy-sweep.tsv` prints `80 30 50` (rows); the same predicate deduplicated on site+generator+geometry+seed+trigger gives 16, 6 and 10 cells, of 42 cells and 210 rows total. The line's claim that no unreached row carries an outcome with a run behind it is unaffected.

## Decisions

- 2026-08-01 (D-020, promoted to `cairn/DECISIONS.md`): static remedy text may name a `ci_method` only on swept evidence over the abort's whole trigger class. Promoted rather than kept local because it binds every future abort in the package, not just these four.
- 2026-08-01 (D-020 Amendment 1, promoted): D-020's bootstrap parenthetical was backwards against its own sweep, and its enforcement claim named a guard the enumerator did not yet have. Corrected by amendment because DECISIONS.md is history and is never edited.
- 2026-08-01 (milestone-local): these guards REPORT the quantities that failed and diagnose nothing. Chosen by the maintainer at the review pass-2 gate after two returns in which a described cause was false in a corner; the alternative, completing the case analysis, was rejected as the approach that had already failed twice. The bootstrap guard, which never diagnosed, is the one that drew no truthfulness finding in either pass.

- 2026-08-01 (milestone-local): the enumeration predicate's LIMITS are stated and
  probed rather than assumed. The scanner is line-oriented over R source, so a
  `ci_method` named in any of six shapes passes ungated: a single-quoted bullet
  string (L1); a named splice, `i = cause` (L2); a quoted bullet name, `"i" = `
  (L3); the method named without the literal `ci_method = "value"` adjacency
  (L4); an abort raised outside the scanner's wrapper list, e.g. `rlang::abort()`
  (L5); an abort call that does not open its line (L6). File scope is a seventh:
  only `R/ci-*.R` is read. Each shape is CONSTRUCTED in `--self-test` and shown
  unmatched, so a limit later closed reds its own probe instead of quietly
  leaving the docstring wrong — verified by widening the method matcher to
  single quotes, which reds L1's probe. `spliced_message_sites()` narrows L2 to
  exactly one shape, a whole line that is a bare identifier, and the five shapes
  it stays blind to are probed the same way. Chosen over widening the scanner:
  widening means resolving R variables, and this milestone's own review history
  is three durable records describing that reporter as a gate on any spliced
  variable, which the `i = cause` probe falsifies. An honest narrow gate is
  citable where a broad claim was not. Recompute:
  `python3 data-raw/enumerate-ci-method-remedies.py --self-test`.

- 2026-08-02 (supersedes the status, not the history, of the three 2026-08-01 entries
  above): D-020 and D-020 Amendment 1 exist NOWHERE in `cairn/DECISIONS.md` on this
  branch — `grep -c 'D-020' cairn/DECISIONS.md` = 0 — and neither ever reached `main`:
  `git diff main..HEAD -- cairn/DECISIONS.md` is empty, T1's re-cut revert having
  removed them with the rest of that file. The first entry above therefore describes a
  promotion that no longer stands, and M101 T2 re-authors D-020 and its amendment as
  ONE correct entry. The two rule statements those entries carry bind NOTHING on this
  branch: D-020's rule (static remedy text may name a `ci_method` only on swept
  evidence over the abort's whole trigger class) and the maintainer's pass-2
  disposition (these guards REPORT the quantities that failed and diagnose nothing).
  Both govern message text; this branch changes no message and `git diff main..HEAD --
  R/` is empty, so neither is live conduct here. Both are M101's to state beside the
  messages they govern — which is what the re-cut moved them for, so that no rule sits
  on `main` while the code breaks it. The entries above are history and stay unedited
  (IP4).

- 2026-08-02 (supersedes, in part, the 2026-08-01 limits entry above): that entry
  states file scope as "a seventh" limit beside L1-L6 and says each stated shape is
  CONSTRUCTED and shown unmatched by a probe. That is wrong by one: `_limit_shapes()`
  holds SIX predicate shapes and `_unreported_splices()` five splice shapes, and no
  probe constructs an abort outside `R/ci-*.R` — none can, the glob being a property
  of the search rather than of the predicate. The live limit set is therefore six
  PROBED predicate shapes (L1-L6), five PROBED unreported splice shapes, and file
  scope STATED WITH NO PROBE. The earlier entry is history and stays unedited (IP4);
  this note is the live statement, and the ledger header and script docstring now
  state the same set. Both carry one canonical `PROBED LIMITS:` line whose two counts
  `--self-test` PARSES and compares with the probe lists, so a record claiming more
  probed limits than exist reds instead of surviving a review — mutation-verified:
  stating seven in the ledger, deleting the line from the docstring, and adding a
  sixth splice probe each red it, and each restored green. Recompute:
  `python3 data-raw/enumerate-ci-method-remedies.py --self-test`.

- 2026-08-02 (RR04, ingested): the four-pass recurrence is primarily an ENFORCEMENT
  defect, not a criteria or authoring one. Every pass was CI-green and
  `cairn_validate`-green throughout, and this repo's own pattern — four `data-raw`
  checkers wired into `lint.yaml` — exists because human gate-reading does not hold
  claims to artifacts at this density. This milestone's checker is the only one of
  the five not wired in. The dominant failure mode is nameable: a figure observed
  once at a terminal, transcribed into prose, never re-derived. Nothing in the
  toolchain distinguishes a transcribed figure from a recomputed one.
- 2026-08-02 (RR04, ingested): AC5 was NOT achievable as written and is retired,
  superseded by RR04's ledger form. Three independent impossibilities: IP4 forbids
  retrofitting commands into historical lines; one claim class ("identical to the
  pre-confirmation run") is unrecomputable in principle because the referent was
  never committed; and mutation red-counts are properties of a mutation, not of the
  tree, so no command over the tree reproduces them. Its real scope lived in a
  work-log line rather than in its own text, so any strict reading failed it. AC2
  WAS achievable — the script docstring already satisfied it — and is retained in
  RR04's parity form, which ties the records to the probe list mechanically.
- 2026-08-02 (RR04, ingested): a re-cut owes a supersession sweep. A re-cut that
  reverts files or moves scope must enumerate the live record surfaces — the
  milestone `## Decisions`, ROADMAP rows, and the file headers of surviving
  artifacts — and append a dated supersession note to each entry the reversion
  falsifies, in the re-cut commit. Criteria quantifying over "this milestone's
  records" are then evaluated over the latest dated statement on each topic. This
  milestone's re-cut did the sweep for the work log and the ROADMAP but not for
  `## Decisions`; that omission is the whole of two pass-4 findings. It edits
  nothing history-protected: supersession is already how amendments work.
- 2026-08-02 (ingest audit, [O] fresh context): RR04's binding set was NOT ingested
  verbatim. The audit found it jointly unsatisfiable in four places and over every
  size limit, with two criteria reproducing the very defect the review diagnosed —
  BC2's "every figure the post-re-cut records state" is an unbounded universal over
  a domain no procedure it names enumerates, and RR04 itself forbids building the
  detector that would bound it. BC2/BC3/BC6 are deferred to a successor milestone;
  BC1, BC7 and BC9 are ingested repaired. Every departure is a row in the
  "Deviations from RR04" table with its ground. The audit independently re-verified
  RR04's factual base (the 210/130/30/50 census, the per-site verdicts,
  `grep -c 'D-020'` = 0, BC10's command), so the departures concern criteria
  structure, never the measurement.

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

**GATE FAILURE — THIRD RETURN. Thrash trigger (a) fires; routed to
`/milestone-plan`, not to another implement pass.** [S] prior-review: 0 findings,
and it independently confirmed every actioned finding from passes 1 and 2 fixed.
[O] diff-bug: 26 findings. Two were reproduced at the gate and are the same defect
class this milestone exists to remove, now in its third distinct form:

- **C1 — the classical message states a requirement the guard does not test.**
  The bullet says "The `F = MSA/MSE` pivot needs a finite, non-zero MSE", but `F`
  goes non-finite when *MSA* does, with MSE finite and non-zero. Reproduced at the
  gate on overflow-scale scores: the user is told the pivot needs a finite,
  non-zero MSE and shown `MSE = 2.5e+199`, which is both. Value-reporting removed
  the false *diagnosis*; it did not stop the message asserting a false
  *requirement*. The npbootstrap sibling states its condition disjunct-for-
  disjunct and is correct.
- **E1 — the splice guard catches one shape and three records claim it catches
  any.** `spliced_message_sites()` requires a whole line to be a bare identifier.
  Reproduced at the gate: `i = cause` — a NAMED bullet splice — passes both
  `--check` and `--self-test`. So do a spliced whole message vector, a bare symbol
  sharing a line with the leading string, `!!!bullets`, and a `paste0()` bullet.
  Meanwhile the ledger header, the self-test comment, and D-020 Amendment 1
  Correction 2 each say "any abort that splices a variable into its message
  vector". This is pass 2's F3 repaired narrowly and re-advertised broadly — the
  identical "record outruns the code" pattern the amendment was written to correct.

**Further findings against this milestone's own records.** P6: the `## Decisions`
section claims the bootstrap guard "drew no truthfulness finding in either pass",
which pass 1's A2 (scored 90) is. D2: D-020 Amendment 1 says the npbootstrap guard
has "three disjuncts, not two" — it has two disjuncts and three causes, an error
inside the correction of an error. N1: NEWS says all three errors now report
quantities; the bootstrap error reports none and still hedges a cause (U3). P4:
the new `burch_ci()` candidate row cites site `990cd66e44`, but those rows are at
`bf1a802a9c`. P5: a live ROADMAP row's stated falsifier has FIRED inside this
milestone — the `gen_se_zero` cell is a measured trigger dataset where four
shipped methods return usable intervals — and neither the row nor the work log
records it. P9: a source comment attributes the report-values decision to the plan
gate; it was the maintainer's at the review pass-2 gate.

**Also logged:** T1 the `diagnosis` regex is three literals under a comment
claiming it catches any cause sentence · T2 nothing pins the reported NUMBERS, so
swapping the two `signif()` arguments leaves the suite green · T3 those pins are
console-width dependent · E2 `SPLICE_ALLOWED` is keyed by file, exempting two
sites where the amendment says one · N2 NEWS calls five methods "applicable" where
one exclusion is a sweep artefact · E3/E4 single-quoted strings and alternate
`ci_method` spellings still escape · C2 the npbootstrap guard is `isTRUE()`-free
and safe only by an unstated invariant · P7 F6 and P8 F11 unfixed from pass 2 ·
T6 pass-1 leftovers · C3/C4/N4 cosmetic.

**Why this is a re-plan and not a fourth patch.** Trigger (a) is mechanical — the
third return — and trigger (b) fires for the third consecutive pass: the same
criterion failing by a new mechanism of the same shape each time. The shape has
been constant across all three passes and has migrated freely between artifacts:
a false cause in a message (pass 1), a false cause in its repair plus a gate
claim that outran its code (pass 2), and now a false requirement in a message
plus a gate claim that outran its code again (pass 3). The plan gate recorded no
alternative on how these messages should be written, because it never framed
"what may this milestone assert, and what checks each assertion" as a question.
That is a scoping defect, not an implementation one, and it is what a re-cut needs
to settle. Local gate and CI are otherwise green throughout, which is the point:
nothing mechanical has ever caught this class.

Every acceptance box unticked.

**Review pass 4 — 2026-08-01 (first pass after the re-cut).** PR #108, head
`12cba54`. `main` unmoved since the branch was cut
(`git rev-list --count HEAD..origin/main` = 0), so all evidence below is current.
Criteria are the RE-CUT set AC1-AC6; the passes above measured a different,
superseded set and none of their evidence is inherited.

**AC1 — enumeration and gate.** `--check` exits 0: 9 `ci_method`-naming reducer
aborts under `R/ci-*.R`, all classified (4 `sweep`, 5 `fence`), committed
enumeration current. Every emitted site carries its file, trigger condition and
named methods (9 each of `key:`, `trigger:`, `names:`); the ledger carries 9 rows;
`grep -c 'R/icc.R'` on the enumeration = 0, so no pre-dispatch design fence
appears. The three `--check` failure modes were DRIVEN, not described: calling
`check()` on each probe's constructed input returns rc 1 for an unclassified site,
rc 1 for a ledger row matching no site, rc 1 for a stale committed enumeration,
and rc 0 on the passing control. The four measured guards are present and anchored
on their own conditions — `n_ok < min_frac * boot_samples`, `ss$mse == 0`,
`obs$se_ij_logf == 0`, `n_bad > 0L` — and are exactly the ledger's four `sweep`
rows, exactly the four keys the sweep script registers, and exactly the four keys
in the committed TSV.

**AC2 — stated limits, each probed.** The predicate's limits are stated in all
three required places: L1-L6 in the script docstring (6 lines), the
`WHAT THIS LEDGER DOES NOT COVER` block in the ledger header, and a
milestone-local `## Decisions` entry. Each of the six is CONSTRUCTED and shown
unmatched by its probe (all six `matched=False`), and the five splice shapes the
reporter does not report are shown likewise (`reported=False`) against a positive
control that IS reported. No record claims broader coverage: the docstring, the
ledger header and the Decisions entry each state the reporter catches one shape
and is not a gate on spliced variables generally.

**AC3 — sweep.** 210 rows over 42 cells (4 sites x 5 methods x geometries), all at
the shipped `boot_samples = 999` (`R/icc.R:552`) and `conf_level = 0.95`.
Geometries per site: 6x3, 10x2, 15x4, 30x3 at exact and near-degenerate triggers
for the three deterministic sites, plus the `SE=0` cell at 3x2; 12x3, 20x3, 30x2
at three seeds for the stochastic resample guard. Usability is the shipped
`boundary_interval_usable()`. Reach is confirmed by the site's own classed
condition from the reducer called DIRECTLY (four `*_ci()` call sites, no `icc()`),
AND by the site's own leading line — necessary because both npbootstrap guards
raise `intraclass_singular_fit` from one reducer. Row census:
130 `reached=TRUE` all with `site_confirmed=TRUE` and `point_fit_ok=TRUE`;
10 site-confirmed but point-fit-failed, excluded; 20 neither; 50 where the reducer
returned an interval. The candidate set is named in the script as five of the
seven shipped `ci_method` values with a stated reason per exclusion (`mpl` fenced
to the balanced two-way random cell; `posterior` needing the brms engine). The six
point-fit-failed cells are excluded from the denominator and each recorded with
the reason "point fit failed: a user could not reach this message on this data".

**AC4 — nothing user-facing, no rule stated.** `git diff main..HEAD --name-only`
lists 7 paths: `cairn/ROADMAP.md`, the milestone file, and five under `data-raw/`.
No path under `R/`, and neither `NEWS.md` nor `cairn/DECISIONS.md`. Stronger than
the criterion asks: `git diff main..HEAD -- R/` is empty, and each of
`R/ci-bootstrap.R`, `R/ci-classical.R`, `R/ci-npbootstrap.R`, `NEWS.md` and
`cairn/DECISIONS.md` is byte-identical to `main`.

**AC6 — toolchain gate.** Suite at `NOT_CRAN=true CI=true` FAIL 0 / PASS 5435 /
SKIP 23 — identical to `main`'s baseline, as expected of a milestone that adds no
R test. `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings
/ 0 notes. `lintr::lint_package()` 0 lints; `air format --check .` clean;
`devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems. All four
other `data-raw` checkers pass, plus this milestone's `--check` and `--self-test`.
Tree clean after every probe.

**Universal cairn checks.** `cairn_validate` exit 0 — 16 PASS including
`coverage complete`, `weight caps`, `mirror agreement`, `binding criteria`;
5 advisory OK; 1 WARN (`dangling id tokens`, 321, pre-existing pre-migration ids).
No `DESIGN.md` principle changed (`git diff main..HEAD -- cairn/DESIGN.md` empty),
so `cairn_impact` does not apply. Profile consistency-gate: no generated file in
the diff, README untouched, no new top-level path, `data-raw` already
`.Rbuildignore`d, and NEWS correctly carries NO entry — this milestone ships no
user-visible change, which AC4 requires.

**CI.** All nine checks pass on `12cba54` (format-check, check-references, lint,
pkgdown, test-coverage, codecov patch + project, ubuntu-latest and windows-latest
release).

**GATE FAILURE — returned to `in-progress` (review pass 4, FOURTH return).**
Three fresh-context lenses ran. [S] prior-review: 0 findings — it verified every
in-scope actioned finding from passes 1-3 (B5, B1, C5, C7, C2, C3, E1/F3, P4, P5,
P6/D2) genuinely fixed against the current code rather than against the work log,
recomputed the four verdicts from the committed TSV, and skipped the GitHub thread
surface after probing it empty. [S] blame-history: 1 finding, scored 25 — the
revert is clean (all five reverted paths byte-identical to `main`, the deleted test
file never existed on `main`, no other milestone's work clobbered), and its one
substantive claim was reconciled against this milestone's own evidence. [O]
diff-bug: 20 findings, 8 scoring >= 80.

**The milestone's own defect class survives, now entirely inside its records.**
Every prior pass found a message or a gate claiming more than the code supported.
This pass finds no such defect in the tooling's behaviour — the enumerator, the
sweep and the committed evidence all verified correct, including an independent
end-to-end re-run of two sweep cells that byte-matched their committed rows. The
defect has migrated wholesale into the records ABOUT that tooling, which is what
AC2 and AC5 were written to prevent, on their first outing.

**Four criteria fail as written.**

- **AC2 fails — O1 (93).** The ledger header enumerates SEVEN shapes the predicate
  misses (L1-L6 plus "anything outside `R/ci-*.R`") and then asserts "Each of those
  shapes is CONSTRUCTED and shown unmatched by a probe"; the milestone `## Decisions`
  entry makes the same claim. `_limit_shapes()` returns SIX. There is no probe
  constructing an abort outside `R/ci-*.R`. AC2's "No record claims detection
  coverage broader than a probe demonstrates" is violated by two durable records —
  the identical shape as pass 3's E1, in the text written to correct pass 3's E1.
  The script docstring is careful here, which makes it a record error, not a code
  error.
- **AC5 fails — O5 (92), O9 (82), O10 (88), O14 (85).** O5: the T2 work-log line
  states "breaking `BULLET_RE` reds 7"; three plausible mutations red 8, 8 and 14,
  and its cited `Recompute:` is `--self-test`, which reproduces neither that figure
  nor the paired "reds 5". O10: "all five `data-raw` checkers pass" where four
  exist besides this milestone's own — the recurrence of pass 1's E5 (68), now
  under a criterion that forbids it. O14: "The 80 unreached rows split 30 point-fit
  failures and 50 cells" — both are row counts; in cells they are 6 and 10. O9: a
  broader pattern of claims carrying no reproducing command, including "Verified
  diagonal on live conditions" and "the per-site reach counts are identical to the
  pre-confirmation run", the latter unrecomputable in principle because that run
  was never committed.
- **AC4 fails on its "states no rule" clause — O11 (82).** The git-diff half
  passes. But the milestone's live `## Decisions` section states D-020's rule
  verbatim, and the maintainer's "these guards REPORT the quantities that failed
  and diagnose nothing" — and the tree, reverted to `main`, breaks both. On merge
  this puts exactly that rule on `main` while the code contradicts it, which the
  Scope section names as the thing the re-cut exists to prevent.
- **AC3 is arguably met but its evidence is narrower than the sweep claims —
  O6 (85).** The classical guard fires on `ss$mse == 0 || !is.finite(f)`; the grid
  feeds it `gen_mse0` alone, so the second disjunct — MSA overflow, precisely
  pass 3's C1 corner — is never generated, while the script header claims coverage
  "across the whole class of data that triggers the abort". Four geometries do
  satisfy AC3's literal "several geometries", so this is recorded as an
  overstatement rather than a criterion failure, and actioned either way.

**Also actioned (>= 80).** O2 (90): the `## Decisions` section says D-020 was
"promoted to `cairn/DECISIONS.md`" and it is not there — `grep -c 'D-020'
cairn/DECISIONS.md` = 0 — a flat falsehood in a live section that no mechanical
check catches.

**Logged below threshold (12, not actioned).** O4 78 nothing runs `--check`, so the
"completeness gate ... cannot reach a release" claim names an enforcement the
toolchain lacks · O12 65 `BULLET_RE` misses cli's other bullet names (`x = `,
`"!" = `), an unstated seventh limit · O3 62 the docstring asserts a leading-line
requirement on M101 that M101 does not impose · O19 62 `_encloses()` counts braces
inside strings and comments, unlike the hardened `_slice_call` · O7 55
`SPLICE_ALLOWED` is keyed by file so it exempts two sites, and its comment names
`mc_ci()` where the splices sit in `rmvn()` and `mc_interval()` (pass 3's E2,
unfixed) · O20 55 single-quoted R strings can desynchronise `_slice_call` ·
O15 52 `gen_se_zero()` ignores all three parameters · O8 50 `check()`'s docstring
says three failure modes where it has four · O16 48 `run_remedy()` re-derives
`divisor` from the printed index rather than the estimand, currently inert
(pass 1's C6) · O13 42 `spliced_in()` silently exempts `c` and `call` · O17 42 no
freshness gate ties the sweep TSV to the guards it measured · O18 32 the
enumeration reports `(unguarded)` for a guard expressed as early returns
(pass 1's B4) · B1 25 the "reachable on macOS too" comment reads as contradicting
M93 but is true and supported by this milestone's own TSV, merely uncited.

**Thrash: trigger (a) fires, and a re-cut has already been spent.** This is the
fourth return on this milestone, counted per milestone and never reset by the
re-cut. Trigger (b) also fires in substance: the same shape — a record asserting
more than the artifact supports — has now failed in four consecutive passes, in a
message (pass 1), in a repair and a gate claim (pass 2), in a requirement and a
gate claim (pass 3), and now in the criteria written specifically to stop it.
Because the work log already records a re-plan spent here, the rulebook's remedy
is no longer re-plan-or-split: the disposition goes to the maintainer, with
escalation offered.

Every acceptance box unticked; the next pass re-verifies from scratch.
