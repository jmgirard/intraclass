<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M51: Statistical-corner guard audit

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M50   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Audit the correct-but-non-obvious statistical corners so each ships a GP7 guard
test plus an in-place comment naming its ADR/D-entry — a future "simplification"
fails a test instead of requiring archaeology (DESIGN.md § Known issues, wart
confirmed 2026-07-12).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** an enumerated inventory of the load-bearing statistical corners derived
from the ADR/D citations across `R/` (~283 hits) cross-checked against the GP7
example set and captured lessons — e.g. the fixed-rater 2b moment correction in
the shared draw helper, the ragged-coverage `n_rep ≥ 240` + per-rep seeding
floor (ADR-042 Amdt 2 / GP5), the cluster-count sweep axis (ADR-046 Amdt 1 /
GP6), the SEM fixed-agreement Case-3A parity, the incomplete-agreement handling;
a per-corner disposition (already-guarded / newly-guarded); and, for any corner
lacking one, a new GP7 guard test + an in-place source comment naming its
ADR/D-entry.

**Out:** the boundary-fit corner's guards → M50 (owns that corner; excluded
here); the cross-engine parity matrix → M49; adding any new statistical
capability or changing behavior — this milestone is test + comment insurance
only.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: A committed audit disposition (in the work log or a short doc)
      enumerates the load-bearing statistical corners with a
      guarded/newly-guarded status each; the inventory is derived from the
      ADR/D citations in `R/` and the GP7 example set, not guesswork, and
      excludes the boundary corner (→ M50).
- [ ] AC2: Every corner in the inventory has a GP7 guard test — one that fails
      if the subtlety is "simplified" away — plus an in-place source comment
      naming its ADR/D-entry; new tests/comments are added where missing, with
      each new guard test demonstrated to fail on the plausible simplification.
- [ ] AC3: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
      NOTEs only); full suite green against the **installed** package with
      `NOT_CRAN=true CI=true` (failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2, T3
- AC3 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Inventory the load-bearing corners — sweep the ADR/D citations across
      `R/` and cross-check the GP7 example set + `cairn/LESSONS.md` / memory
      (fixed-rater 2b moment; ragged `n_rep ≥ 240`; cluster-count axis; SEM
      Case-3A parity; incomplete-agreement). Record a guarded/unguarded
      disposition per corner, excluding the boundary corner (→ M50).
- [ ] T2: For each corner lacking one, add a GP7 guard test that fails on the
      plausible "simplification" (demonstrate the red before the green).
- [ ] T3: For each corner lacking one, add the in-place source comment naming
      its ADR/D-entry.
- [ ] T4: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs and
      update the DESIGN.md § Known-issues note to reference M51.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan ("address known issues" run). Plan
  gate: three separate hardening milestones (M49/M50/M51), all sequenced before
  the M48 release; depends on M50 so the boundary corner is already
  policy-guarded and excluded from this audit.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
