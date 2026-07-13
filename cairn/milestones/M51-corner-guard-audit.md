<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M51: Statistical-corner guard audit

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M50   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5, GP6, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m51-corner-guard-audit   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: A committed audit disposition (a short table in the milestone work
      log) enumerates the load-bearing statistical corners with an
      already-guarded / newly-guarded status each, and lists the ADRs the filter
      excludes with a one-line reason. The inventory is derived from the ADR/D
      citations in `R/` filtered by the "silently wrong number" bar (see Scope)
      plus the GP5/GP6/GP7 example set + LESSONS/memory, not guesswork, and
      excludes the boundary corner (→ M50) and parity (→ M49).
- [ ] AC2: Every in-scope corner ends GP7-guarded: either an existing test is
      shown to go red when the plausible simplification is applied
      (already-guarded — cite the test), or a new guard test that fails on that
      simplification is added to `test-corner-guards.R` (newly-guarded —
      demonstrate the red before the green). Every corner also carries an
      in-place source comment in `R/` naming its ADR/D-entry.
- [ ] AC3: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
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
- [ ] T2: For each newly-guarded corner, add a guard test to a new consolidated
      `tests/testthat/test-corner-guards.R` (mirror `test-boundary-policy.R`'s
      header pattern) that fails on the plausible simplification — demonstrate
      the red before the green and record it in the work log.
- [ ] T3: For each in-scope corner lacking one, add the in-place source comment
      in `R/` naming its ADR/D-entry.
- [ ] T4: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs and
      flip the DESIGN.md § Known-issues "Statistical corners are held by ADR
      memory" bullet to RESOLVED-by-M51 (mirroring the M49/M50 bullets).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan ("address known issues" run). Plan
  gate: three separate hardening milestones (M49/M50/M51), all sequenced before
  the M48 release; depends on M50 so the boundary corner is already
  policy-guarded and excluded from this audit.
- 2026-07-12: /milestone-plan refinement (M50 now done, M51 workable). Plan gate
  settled three open scoping decisions (user deferred to recommendations):
  inventory bounded by a curated-seed + "silently wrong number" filter over the
  ~40 R/ ADRs (not exhaustive); a corner counts as already-guarded only if an
  existing test goes red on the plausible simplification (else add a guard); new
  guards consolidated into one `test-corner-guards.R` mirroring M50's
  `test-boundary-policy.R`. Principles-touched widened to GP5/GP6/GP7 (those
  corners are in scope). No behavior change; scope unchanged in substance.

- 2026-07-12: T1 inventory (disposition confirmed by reading + one mutation
  probe). Kept corners (filter = "a plausible simplification silently yields a
  wrong number", excluding abort paths + M49/M50):
  - **A. Fixed-rater 2b moment family** — `theta2r_moment_draws` /
    `theta2r_nested_draws` (engine-glmmtmb.R) + `brms_theta2r_moment_draws`
    (engine-brms.R); subtlety = subtract **2b not 1b** and floor the **average
    not per-group** (ADR-037/038). **NEWLY-GUARDED**: mutation probe showed the
    frozen coverage fixture (O-NFI) can't move and the live containment check
    (O-NFI/point) stays 1.000 under both 2b→1b and per-group-floor → gap.
  - **B. brms MAP point** = mode of the ICC-draw vector, not
    `icc_point(modal components)` (ADR-033). already-guarded — non-Stan live
    recompute at test-icc-brms.R:386-387.
  - **C. SEM fixed-agreement Case-3A** θ²_r distinct from raw, reduces to
    glmmTMB fixed+random (M21). already-guarded — test-icc-lavaan.R:320,357.
  - **D. Ragged coverage `n_rep ≥ 240` + per-rep seeding** (GP5, ADR-042 Amdt2).
    Pinned for incomplete-multilevel (test-icc-incomplete-multilevel.R:563) but
    **NEWLY-GUARDED** for the incomplete-fixed-nested fixture (no n_rep pin;
    fixture stores n_rep=240 → cheap metadata pin).
  - **E. Cluster-count sweep axis** high-C_n cell present (GP6, ADR-046 Amdt1).
    already-guarded — O-NFI `by_cn(80,·)` requires C_n=80 in the grid.
  - **F. Incomplete-agreement handling** (raw-SEM bias / FIML). already-guarded
    — live O5 lme4 + recovery at test-icc-incomplete.R:97,147.
  Excluded (listed, not dropped): boundary/near-zero corner → M50 (D-004);
  cross-engine parity matrix → M49; abort/identifiability/Heywood/singular
  deferral paths → they fail loudly (#5), not silently wrong, covered by
  error-branch tests; choose_icc emitted-type (ADR-021) + warning-not-error
  (ADR-006) → output-shape/behavior, not a silent numeric subtlety.
  Net new work: A (3 direct helper guards) + D (one n_rep pin); B/C/E/F cite
  their existing live guard; in-place R/ ADR comments for A already present.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
