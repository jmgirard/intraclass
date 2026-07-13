<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M50: Boundary-fit convergence policy consolidation

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m50-boundary-policy   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Replace the accumulated per-milestone boundary-fit case law (near-zero /
singular variance components) with one documented, principled policy plus guard
tests, without changing behavior (DESIGN.md § Known issues, wart confirmed
2026-07-12).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** an audit of the current near-zero / singular boundary handling across
the four engines and the three CI methods — the scattered case law of ADR-002
(glmmTMB log-SD smooth boundary), ADR-003 (boundary-aware MC), ADR-012 (lme4
singular-fit deferral, `R/engine-lme4.R:79`), ADR-025 (bootstrap component-at-0
KEPT policy) and the CI-method files (`R/ci-montecarlo.R`, `R/ci-bootstrap.R`,
`R/ci-posterior.R`); a single consolidated boundary-fit policy written to
DESIGN.md; a D-entry recording that policy and summarizing the legacy ADRs by
citation; and guard/regression tests pinning each engine's documented boundary
behavior (GP7). Promotes and resolves the "Boundary-fit convergence policy
consolidation" ROADMAP candidate row.

**Out:** *changing* boundary behavior — this milestone documents and pins
existing behavior. Any code/policy inconsistency the audit surfaces that would
warrant a behavior change escalates at the gate (it touches the boundary-aware
interval contract, PRINCIPLES.md #3), never folded in silently. The
cross-engine parity matrix → M49; the general statistical-corner guard audit →
M51 (this milestone owns the **boundary** corner's guards specifically, so M51
excludes it).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: A consolidated boundary-fit policy section exists in DESIGN.md
      covering, per engine and per CI method, how a near-zero / singular
      variance component is handled (kept-at-0 vs classed deferral vs smooth
      log-SD); every behavior claim cites the governing ADR/D-entry.
- [ ] AC2: A D-entry in `cairn/DECISIONS.md` records the consolidated policy
      and cites **every** legacy ADR the T1 audit surfaces as governing boundary
      behavior — the known core (ADR-002, ADR-003, ADR-012, ADR-025) plus any
      additional boundary-relevant ADRs the audit turns up (the engine/CI files
      also cite ADR-030, ADR-037, ADR-038, ADR-044, ADR-046 around floors and
      boundary handling; the audit confirms which govern) — superseding the
      "case law" status without changing behavior.
- [ ] AC3: Guard/regression tests pin each engine's documented boundary
      behavior — e.g. the lme4 singular-fit classed abort `intraclass_singular_fit`
      (`R/engine-lme4.R:79`), the glmmTMB finite-boundary interval, the
      bootstrap/MC component-at-0 KEPT draw — each test naming its ADR/D-entry
      (GP7). A code/policy mismatch stops for a gate.
- [ ] AC4: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
      NOTEs only); full suite green against the **installed** package with
      `NOT_CRAN=true CI=true` (failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Audit boundary handling — enumerate every near-zero / singular code
      path across `R/engine-*.R` (lme4 heaviest ~63 hits; glmmTMB ~17; brms,
      lavaan) and `R/ci-*.R`, each with its governing ADR/D-entry and current
      behavior; produce the per-engine × per-CI-method behavior table.
      (RB tripwire: ip-touching)
- [ ] T2: Write the consolidated boundary-fit policy section in DESIGN.md from
      the audit table.
- [ ] T3: Append the consolidating D-entry to `cairn/DECISIONS.md` citing the
      summarized legacy ADRs; resolve the "Boundary-fit convergence policy
      consolidation" candidate row.
- [ ] T4: Add / confirm guard tests pinning each documented boundary behavior,
      each citing its ADR/D-entry (GP7); a code/policy mismatch stops for a
      gate rather than a silent behavior edit.
- [ ] T5: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs and
      update the DESIGN.md § Known-issues note to reference M50.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan ("address known issues" run; promotes
  the boundary-policy candidate row). Plan gate: three separate hardening
  milestones (M49/M50/M51), all sequenced before the M48 release; document +
  pin existing behavior, escalate any surfaced inconsistency.
- 2026-07-12: /milestone-plan re-pass (planned-collision) verified code
  citations still accurate (`R/engine-lme4.R:79` = `intraclass_singular_fit`).
  AC2 opened from a closed 4-ADR list to "every ADR the T1 audit surfaces" —
  code also cites ADR-030/037/038/044/046 around boundary/floor handling.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
