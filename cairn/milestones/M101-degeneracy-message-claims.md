# M101: What a degeneracy message may assert, and the messages made to obey it

- **Status:** planned
- **Priority:** normal
- **Depends on:** M100
- **Driving RR:** —
- **Principles touched:** GP1, GP7
- **Branch/PR:** —

## Goal

Every CI-reducer degeneracy message asserts only what its own guard establishes,
under a stated rule, with each assertion covered by a fixture that reaches it.

## Scope

**In:** the four degeneracy guards M100's ledger marks — `bootstrap_ci()`'s
refit-convergence guard, `classical_guard_observed()`, and `npbootstrap_ci()`'s
observed-data and degenerate-resample guards. Removing the `ci_method` names
M100's sweep condemned; correcting the two diagnostic bullets M100's review
proved false on `main`; a `cairn/DECISIONS.md` entry stating what such a message
may assert; per-guard assertion tables; fixtures reaching every disjunct and
cause; NEWS.

**Out:** `icc()`'s pre-dispatch design and argument fences — they refuse a design,
not degenerate data (M100 Scope). Extending M93's runtime `boundary_method_hint()`
to these sites → ROADMAP candidate row, whose stated falsifier M100's sweep has
now FIRED (the `gen_se_zero` cell is a measured trigger dataset where four
shipped methods return usable intervals); the row is corrected in this milestone
rather than acted on. `burch_ci()`'s raw unclassed error on SSA = 0 data →
ROADMAP candidate row. The measurement tooling itself → M100.

## Acceptance criteria

- [ ] AC1 `cairn/DECISIONS.md` gains an entry stating what a CI-reducer
      degeneracy message may assert about the user's data and what licenses each
      kind of assertion, including that a `ci_method` may be named only where
      M100's sweep found it usable on every dataset that reached that site, and
      what governs a site the sweep never covered. Every factual claim the entry
      makes about a measured result names the committed artifact and the command
      that recomputes it.
- [ ] AC2 For each guard M100's ledger marks, a committed table enumerates every
      assertion its shipped message makes — about the data, about what the method
      requires, and about what another method would do — and maps each to the part
      of the guard's condition that entails it. An assertion no part of the
      condition entails is removed from the message before this milestone ships.
- [ ] AC3 Committed fixtures reach every disjunct of each guard's condition and
      every distinguishable cause within those disjuncts, including the
      non-finite and overflow corners, and a test asserts per fixture that each
      assertion AC2's table lists for that message holds on it. The table names
      which fixture covers which assertion, and each test is mutation-verified by
      restoring the pre-milestone text and recording that the suite reds.
- [ ] AC4 Every shipped abort under `R/ci-*.R` that names a `ci_method` either has
      M100 sweep evidence that the named method is usable on every dataset that
      reached it, or carries a recorded ground for naming it without such
      evidence; sites with neither name no method and still carry an imperative
      the user can act on.
- [ ] AC5 Every claim this milestone's records make — in the D-entry, in NEWS, in
      the milestone file — about what a mechanism enforces, catches, or measured
      is demonstrated by a command or probe that is named beside the claim and
      that fails when the claimed thing is not so.
- [ ] AC6 If this milestone changes any guard's condition, M100's sweep is re-run
      and its committed results updated, so no record cites evidence gathered
      against a different condition.
- [ ] AC7 The profile `verify` slot is clean, plus the fuller pre-review check it
      names, with every `data-raw` checker run locally.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T2, T5
- AC6 → T4
- AC7 → T6

## Tasks

- [ ] T1 Build the per-guard assertion table: read each shipped message, list
      every assertion it makes, and map each to the part of the guard's condition
      entailing it; mark the unentailed ones for removal.
- [ ] T2 Author the `cairn/DECISIONS.md` entry (re-authoring the branch's removed
      D-020 and its amendment as ONE correct entry), with a recompute command
      beside every measured claim.
- [ ] T3 Write the fixtures and per-assertion tests, covering every disjunct and
      cause including the non-finite and overflow corners; mutation-verify each.
- [ ] T4 Edit the messages: drop the condemned `ci_method` names, remove or
      correct the unentailed assertions T1 marked, record the ground for any
      surviving method name, and re-run M100's sweep if any condition changed.
- [ ] T5 `NEWS.md` entry; add the demonstrating command beside every record claim
      about enforcement or measurement; correct the runtime-hint candidate row
      whose falsifier has fired.
- [ ] T6 Gate: full suite at `NOT_CRAN=true CI=true`, `devtools::check()`,
      `lintr::lint_package()`, `air format --check`, every `data-raw` checker.

## Work log

- 2026-08-01: created by /milestone-plan, re-cutting M100 after its third review return (thrash trigger (a)). Takes every message change and the rule governing them; M100 keeps measurement and tooling.
- 2026-08-01: re-cut gate chose landing the rule WITH the messages it governs over landing it beside M100's sweep evidence, because a rule on `main` while the shipped code breaks it is itself a record claiming more than the tree supports; falsified by a reader finding the rule unusable without the sweep in the same PR.
- 2026-08-01: re-cut gate chose re-authoring D-020 and its amendment as one correct entry over appending a third amendment, on the maintainer's disposition that neither has reached `main` so nothing history-protected is edited; falsified by evidence either had shipped.
- 2026-08-01: criteria audit ([O], fresh context) ran over the rewritten set and returned three gaps, all fixed before this file was written: the enumeration predicate was unanchored so the whole evidence chain could be satisfied vacuously (M100 AC1 now names the four guards); this milestone had no counterpart to M100's probe-backed limits rule, so the pass-2/pass-3 defect could recur verbatim in its own D-entry (AC5); and the sweep-evidence rule was vacuous at sites the sweep never covered, leaving five shipped sites naming a method on zero evidence (AC4). Also broadened the recompute rule past sweep numbers to counts, keys and self-history claims, added mutation-verification to AC3, derived the guard set from M100's ledger rather than a hardcoded count, and added AC6 so a condition change cannot leave cited evidence stale.

## Decisions

## Review
