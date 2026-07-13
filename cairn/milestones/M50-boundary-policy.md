<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M50: Boundary-fit convergence policy consolidation

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m50-boundary-policy · https://github.com/jmgirard/intraclass/pull/56   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: A consolidated boundary-fit policy section exists in DESIGN.md
      covering, per engine and per CI method, how a near-zero / singular
      variance component is handled (kept-at-0 vs classed deferral vs smooth
      log-SD); every behavior claim cites the governing ADR/D-entry.
- [x] AC2: A D-entry in `cairn/DECISIONS.md` records the consolidated policy
      and cites **every** legacy ADR the T1 audit surfaces as governing boundary
      behavior — the known core (ADR-002, ADR-003, ADR-012, ADR-025) plus any
      additional boundary-relevant ADRs the audit turns up (the engine/CI files
      also cite ADR-030, ADR-037, ADR-038, ADR-044, ADR-046 around floors and
      boundary handling; the audit confirms which govern) — superseding the
      "case law" status without changing behavior.
- [x] AC3: Guard/regression tests pin each engine's documented boundary
      behavior — e.g. the lme4 singular-fit classed abort `intraclass_singular_fit`
      (`R/engine-lme4.R:79`), the glmmTMB finite-boundary interval, the
      bootstrap/MC component-at-0 KEPT draw — each test naming its ADR/D-entry
      (GP7). A code/policy mismatch stops for a gate.
- [x] AC4: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
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

- [x] T1: Audit boundary handling — enumerate every near-zero / singular code
      path across `R/engine-*.R` (lme4 heaviest ~63 hits; glmmTMB ~17; brms,
      lavaan) and `R/ci-*.R`, each with its governing ADR/D-entry and current
      behavior; produce the per-engine × per-CI-method behavior table.
      (RB tripwire: ip-touching)
- [x] T2: Write the consolidated boundary-fit policy section in DESIGN.md from
      the audit table.
- [x] T3: Append the consolidating D-entry to `cairn/DECISIONS.md` citing the
      summarized legacy ADRs; resolve the "Boundary-fit convergence policy
      consolidation" candidate row.
- [x] T4: Add / confirm guard tests pinning each documented boundary behavior,
      each citing its ADR/D-entry (GP7); a code/policy mismatch stops for a
      gate rather than a silent behavior edit.
- [x] T5: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs and
      update the DESIGN.md § Known-issues note to reference M50.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12 (plan): created ("address known issues"); promotes the
  boundary-policy candidate. Re-plan pass opened AC2 to "every ADR the audit
  surfaces." (Detail in git history.)
- 2026-07-12 (T1–T2): audited near-zero/singular handling across the 4 engines +
  3 CI methods; wrote `DESIGN.md § Boundary-fit policy` (per-engine + per-CI
  tables, 3 behaviors, each cell citing its ADR). Pure pin, no behavior change.
- 2026-07-12 (T3): D-004 consolidating the governing ADRs. No candidate row left
  (already promoted at plan time).
- 2026-07-12 (T4): new `tests/testthat/test-boundary-policy.R` — one guard per
  policy cell, each citing its ADR + D-004.
- 2026-07-12 (T5): Known-issues wart marked resolved. check(NOT_CRAN=false) +
  installed-pkg suite (NOT_CRAN=true CI=true) both 0/0/0; lintr clean. → review.
- 2026-07-12 (review): fixed doc/test gaps from the three-lens review (added
  ADR-023/024; documented the bootstrap non-convergent-warning path; strengthened
  guards to non-vacuous; corrected brms/floor framing). No code change.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Verified 2026-07-12 — fresh evidence, by command (not recall):**

- **AC1 ✓** `DESIGN.md § Boundary-fit policy` exists: per-engine (fit-time) +
  per-CI-method (interval-time) tables, 3 behaviors, every cell citing its ADR.
- **AC2 ✓** D-004 records the policy and cites the full governing set
  (002/003/012/014/023/024/025/031/033/037/038/044) — review added 023/024.
- **AC3 ✓** `test-boundary-policy.R` 14/14 pass (no skips); one non-vacuous guard
  per policy cell, each naming its ADR + D-004.
- **AC4 ✓** `check(NOT_CRAN=false)` 0/0/0 (review re-ran twice, post-fix included);
  installed-pkg `NOT_CRAN=true CI=true` 0/0/0 (T5, skip_on_cran paths exercised).
- **Consistency gate:** `cairn_validate` exit 0; `document()` no-diff; NAMESPACE
  unchanged (no new exports → pkgdown index unaffected); NEWS n/a (no user-visible
  change); air + lintr clean.
- **Independent review (3 lenses + verification):** diff-bug [O] and blame-history
  [S] each surfaced real doc/test gaps — omitted ADR-023/024, under-documented
  bootstrap warning path, and vacuous guard assertions — all verified against the
  primary ADRs, scored ≥80, and **fixed on the branch** (no code change).
  Prior-PR-comments [S] lens: no prior-PR evidence (no-op). 0 findings deferred,
  0 below-threshold.
