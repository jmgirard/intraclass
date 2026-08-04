# M100: Abort remedies name only a `ci_method` measured to work on the data that triggers them

- **Status:** blocked
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6, GP7
- **Branch/PR:** `m100-abort-remedy-truthfulness` / https://github.com/jmgirard/intraclass/pull/108 (draft)

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
      names, with the three `data-raw` checkers run locally.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2, T3
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks

- [ ] T1 `data-raw/enumerate-ci-method-remedies.py` — scan `R/ci-*.R` for classed
      aborts whose message bullets name a `ci_method` value and whose trigger is
      observed-data or resample degeneracy; commit its output table.
- [ ] T2 `data-raw/sweep-abort-remedies.R` — per enumerated site, generate
      several geometries meeting its trigger condition, confirm the abort fires
      from the reducer called directly, run each named method, and classify the
      result through `boundary_interval_usable()`; commit the results table.
- [ ] T3 Rewrite the remedies T2 condemns, at each site keeping its abort class
      and leading line: `bootstrap_ci()` (`R/ci-bootstrap.R:48`),
      `classical_guard_observed()` (`R/ci-classical.R`), and the two
      `npbootstrap_ci()` degeneracy guards (`R/ci-npbootstrap.R`).
- [ ] T4 Tests firing each rewritten abort at its reducer directly — a stub
      `simulate_refit` for the bootstrap site, raw degenerate frames for the
      others — asserting no condemned method is named; mutation-verify each by
      restoring the old bullet.
- [ ] T5 `NEWS.md` entry, the `cairn/DECISIONS.md` entry, and any snapshot
      refreshed by the changed text.
- [ ] T6 Gate: full suite at `NOT_CRAN=true CI=true`, `lintr::lint_package()`,
      `air format --check`, and the three `data-raw` checkers.

## Work log

- 2026-08-01: created by /milestone-plan; absorbs the ROADMAP candidate row on `R/ci-bootstrap.R:48`'s untruthful remedy (lineage M93 T1 → M93 AC2 amendment → M93 re-cut → here).
- 2026-08-01: plan gate chose all four reducer-stage sites over the bootstrap site alone because one sweep harness covers all four and three known-misleading messages would otherwise ship; falsified by evidence a sibling's trigger set differs enough that one harness cannot reach it.
- 2026-08-01: plan gate chose a seeded sweep of each trigger class over a single triggering dataset per site because static text must hold for every dataset reaching that abort and D-018 records that one run is evidence about one seed; falsified by evidence a site's trigger condition admits only one dataset shape.
- 2026-08-01: plan gate chose rewriting static message text over splicing M93's runtime `boundary_method_hint()` into these sites because M93 T1 measured the bootstrap site 0/90 at the boundary and every candidate method aborting on the degenerate data that does reach it, so the machinery would emit nothing; falsified by a measured trigger dataset where some shipped `ci_method` returns a usable interval.
- 2026-08-01: plan gate chose a ROADMAP candidate row over a follow-on milestone for the ledger + CI checker, at the user's direction.
- 2026-08-01: criteria audit ([O], fresh context) returned six findings; five fixed before the gate — scope narrowed to reducer-stage degeneracy aborts (the `icc()`-body fences have no reducer, so the draft AC2 was unsatisfiable there), the invented three-way outcome classification replaced by the shipped `boundary_interval_usable()`, AC4's vacuous "each rewritten abort" quantifier bound to the audited set, the rewritten remedy required to stay actionable (#8/GP1) rather than merely losing a bullet, and AC6's rule scoped to static text so it cannot contradict D-018's runtime route. The sixth (evidence bar) went to the gate as a question.
- 2026-08-03: mirror catch-up by /milestone — ROADMAP carries `Depends on: —` for this milestone (M102 discharged its blocker at M102 done, 2026-08-03) while this header still read M102; ROADMAP wins, so the header is aligned. Bookkeeping only, no work performed.
- 2026-08-03: git-reconciliation catch-up by /milestone — branch `m100-abort-remedy-truthfulness` and draft PR #108 (opened 2026-08-02) existed with this header reading `Branch/PR: —`; header now records both. Bookkeeping only, no work performed.
- 2026-08-03: blocker recorded by /milestone — status has been `blocked` since D-021 (2026-08-03) barred records-verification milestones without a trigger in what the package computes; this milestone resumes only once it names the wrong user-facing behaviour motivating it, otherwise it is dropped and its content folds into the milestone that next touches these abort paths. Bookkeeping only, no work performed.

## Decisions

## Review
