<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M51: Statistical-corner guard audit

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M50   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5, GP6, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m51-corner-guard-audit · https://github.com/jmgirard/intraclass/pull/57   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Audit the correct-but-non-obvious statistical corners so each ships a GP7 guard
test plus an in-place comment naming its ADR/D-entry — a future "simplification"
fails a test instead of requiring archaeology (DESIGN.md § Known issues, wart
confirmed 2026-07-12).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** an enumerated inventory of the load-bearing statistical corners, bounded
by a **curated + filtered sweep** (plan gate 2026-07-12): seed from the GP5/GP6/
GP7 example corners + corners named in `cairn/LESSONS.md` and memory, then scan
the ADR/D citations across `R/` (~40 distinct ADRs) keeping only corners where a
plausible "simplification" would **silently yield a wrong number** (not an abort,
not a corner already owned by M49/M50) — expected ~6–10 corners. Named seeds: the
fixed-rater 2b moment correction in the shared draw helper (ADR-038/037), the
ragged-coverage `n_rep ≥ 240` + per-rep seeding floor (ADR-042 Amdt 2 / GP5), the
cluster-count sweep axis (ADR-046 Amdt 1 / GP6), the SEM fixed-agreement Case-3A
parity, the incomplete-agreement handling. Per corner: a disposition of
**already-guarded** (an existing test goes red when the plausible simplification
is applied) vs **newly-guarded** (nothing catches it → add a guard). New guard
tests land in one consolidated `tests/testthat/test-corner-guards.R` (mirrors
M50's `test-boundary-policy.R`); the in-place source comment naming the ADR/D-entry
lives next to the code in `R/`.

**Out:** the boundary-fit corner's guards → M50 (owns that corner; excluded
here); the cross-engine parity matrix → M49; adding any new statistical
capability or changing behavior — this milestone is test + comment insurance
only. ADRs the filter excludes (an abort path, or already M49/M50-owned) are
listed in the inventory with the one-line reason they are out, not silently
dropped.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: A committed audit disposition (a short table in the milestone work
      log) enumerates the load-bearing statistical corners with an
      already-guarded / newly-guarded status each, and lists the ADRs the filter
      excludes with a one-line reason. The inventory is derived from the ADR/D
      citations in `R/` filtered by the "silently wrong number" bar (see Scope)
      plus the GP5/GP6/GP7 example set + LESSONS/memory, not guesswork, and
      excludes the boundary corner (→ M50) and parity (→ M49).
- [x] AC2: Every in-scope corner ends GP7-guarded: either an existing test is
      shown to go red when the plausible simplification is applied
      (already-guarded — cite the test), or a new guard test that fails on that
      simplification is added to `test-corner-guards.R` (newly-guarded —
      demonstrate the red before the green). Every corner also carries an
      in-place source comment in `R/` naming its ADR/D-entry.
- [x] AC3: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
      NOTEs only); full suite green against the **installed** package with
      `NOT_CRAN=true CI=true` (failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T1 (already-guarded dispositions), T2 (new guard tests), T3 (source comments)
- AC3 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Inventory the load-bearing corners. Seed from the GP5/GP6/GP7 example
      set + `cairn/LESSONS.md` / memory (fixed-rater 2b moment; ragged
      `n_rep ≥ 240`; cluster-count axis; SEM Case-3A parity; incomplete-
      agreement), then sweep the ADR/D citations across `R/` and keep only
      corners passing the "silently wrong number" filter (excluding abort paths
      and M49/M50-owned corners). For each kept corner, apply the plausible
      simplification and check whether any existing test goes red → record an
      already-guarded (cite the test) / newly-guarded disposition. Write the
      inventory table (kept corners + excluded-ADR reasons) into the work log.
- [x] T2: For each newly-guarded corner, add a guard test to a new consolidated
      `tests/testthat/test-corner-guards.R` (mirror `test-boundary-policy.R`'s
      header pattern) that fails on the plausible simplification — demonstrate
      the red before the green and record it in the work log.
- [x] T3: For each in-scope corner lacking one, add the in-place source comment
      in `R/` naming its ADR/D-entry.
- [x] T4: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs and
      flip the DESIGN.md § Known-issues "Statistical corners are held by ADR
      memory" bullet to RESOLVED-by-M51 (mirroring the M49/M50 bullets).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan ("address known issues"); one of three
  hardening milestones (M49/M50/M51) before the M48 release; depends on M50 (its
  boundary corner is excluded here).
- 2026-07-12: /milestone-plan refinement. Gate settled three scoping decisions
  (user deferred to recommendations): curated-seed + "silently wrong number"
  filter (not exhaustive); already-guarded = an existing test goes red on the
  simplification; guards consolidated in one `test-corner-guards.R`. Principles
  widened to GP5/GP6/GP7. No behavior change.

- 2026-07-12: T1 inventory (full table: test-corner-guards.R header + git).
  Filter = "plausible simplification → silently wrong number", excluding abort
  paths + M49/M50. Six kept corners: **A** fixed-rater 2b moment family (2b-not-1b
  + average- not per-group floor, ADR-037/038) and **D** ragged `n_rep≥240` on the
  incomplete-fixed-nested fixture (GP5) are **NEWLY-GUARDED** (A mutation-confirmed:
  frozen O-NFI fixture can't move, live containment stays 1.000 under both
  simplifications); **B/C/E/F** (brms MAP mode, SEM Case-3A, cluster axis,
  incomplete-agreement) already-guarded by cited live tests. Excluded, listed:
  boundary → M50, parity → M49, abort/Heywood paths (fail loudly, not silent),
  choose_icc/warning (output-shape, not numeric).

- 2026-07-13: T2/T3. New `test-corner-guards.R`: A = 3 helper guards (2b-not-1b +
  average-floor, hand-computed) + D = n_rep≥240 pin; header cross-refs B/C/E/F.
  Red demonstrated via source patch (2b→1b, per-group-floor), reverted. One-line
  guard reference added at each helper. Suite FAIL 0 | PASS 1655 | SKIP 23.
- 2026-07-13: T4. Installed `devtools::check` clean both ways (`NOT_CRAN=false`;
  `NOT_CRAN=true CI=true`): 0/0/0 each (`manual=FALSE`, [[rcmdcheck-pdf-manual-courier]]).
  `air` + `lint_package` clean. DESIGN.md Known-issues bullet → RESOLVED-by-M51.
  Status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

- 2026-07-13 (PR #57). **AC1** ✓ — inventory table (6 corners + excluded ADRs
  with reasons) committed in the work log. **AC2** ✓ — guard file green (9/9);
  fresh red-demo (2b→1b trips the freq assertions); already-guarded B/C/E/F
  citations verified live by the diff-bug reviewer; in-place R/ ADR comments
  present. **AC3** ✓ — fresh installed `devtools::check`: `NOT_CRAN=false`
  0/0/0 and `NOT_CRAN=true CI=true` 0/0/0.
- Consistency gate: `cairn_validate` exit 0 (all checks); coverage complete;
  `cairn_impact` — M51 changed no GP wording (only a Known-issues bullet), all
  citations valid. `air` + `lintr::lint_package()` clean (0).
- Three-lens review: [O] diff-bug — no findings (numeric claims re-executed);
  [S] prior-PR — no-ops (no substantive prior comments on these files); [S]
  blame-history — 1 finding (scored 85, actioned): nested guard test titled
  ADR-046 but the 2b/average-floor subtlety is ADR-038's (ADR-046 only
  generalizes to unequal k; fixture is equal-k) → title + comment corrected.
  1 sub-80 observation (a tautological `expect_false(all.equal(literal))`)
  cleaned opportunistically. Post-fix: 0 lints, guards green.
