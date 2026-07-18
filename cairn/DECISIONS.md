# Decisions

Append-only. Never renumber; supersede with a new entry. D-entries record
choices with rationale — never deferrals ("not now" is a ROADMAP fact).

**Pre-migration decisions:** the full architecture-decision log (ADR-001..058,
~5000 lines) is entombed verbatim at
[`cairn/legacy/DECISIONS.md`](legacy/DECISIONS.md) and stays valid as a citation
target — source comments, tests, and tracking cite `ADR-0nn` into it. cairn's
`DECISIONS.md` starts fresh at D-001; still-governing legacy decisions are cited
by their `ADR-0nn` id rather than re-recorded (per the `/cairn-init` migration
pointer-only choice, 2026-07-12). New cross-cutting decisions are appended here.

### D-001 (2026-07-12): IP/GP formalization — strength tags in place, new principles in DESIGN.md

**Context:** cairn's IP/GP taxonomy had been deferred at migration; ~70 in-code
`PRINCIPLES.md #N` citations (concentrated on #1×26, #5×20, #8×8) must not strand.
**Decision:** `PRINCIPLES.md` stays the authoritative home for `#1`–`#19`, each
strength-tagged in place — IP: #1–#5, #12, #19; GP: #6–#10, #11 (as amended,
D-002), #13, #18 — with two fences: #3's *default interval method* is tradeable
via D-entry (the IP core is "always an interval, boundary-aware, method
reported"), and #8's essence is *classed, actionable conditions* (`cli` is the
idiom, not the commitment). Interview-derived principles live in `DESIGN.md` as
IP1–IP3 / GP1–GP7.
**Consequences:** two homes, one taxonomy; in-code citations untouched; new
principles are cited as `DESIGN.md IPn/GPn`.

### D-002 (2026-07-12): Amend #11 — coverage is a diagnostic, never a gate

**Context:** #11 claimed a ≥90% target with CI failing on coverage regression;
actual practice is a deliberate ~88% baseline (untestable defensive abort
branches) and CI enforces no threshold — the constitution and CI disagreed.
**Decision:** #11 rewritten to honest practice: oracle coverage of statistical
paths is the real bar; `covr` is a diagnostic with no numeric target or CI gate.
Tagged GP.
**Consequences:** the constitution matches what CI demonstrably does; coverage
regressions surface via review judgment, not a mechanical gate.

### D-003 (2026-07-12): Retire #14–#17 — process absorbed by cairn

**Context:** plan-before-code (#14), thin slices (#15), tracking currency (#16),
and scope discipline (#17) are now owned and mechanically enforced by the cairn
rulebook; none has in-code citations.
**Decision:** #14–#17 retired with a tombstone note in `PRINCIPLES.md`; numbers
stay retired, never reused. #18 stays GP; #19 stays IP.
**Consequences:** single owner for process rules (cairn); the constitution keeps
statistical, software, and conduct principles only.

### D-004 (2026-07-12): Consolidated boundary-fit policy — one policy, existing behavior pinned

**Context:** Near-zero / singular variance components — the boundary of the
parameter space, and the common applied case for interrater data — were handled
by accumulated per-milestone case law scattered across the four engines and three
CI methods, governed by ADR-002, ADR-003, ADR-012, ADR-014, ADR-023, ADR-024,
ADR-025, ADR-031, ADR-033, ADR-037, ADR-038, and ADR-044 (the lme4 singular-fit
guard is introduced by ADR-012 and reused per shape via ADR-023/024), with no
single statement of the policy (the `DESIGN.md § Known issues` wart, confirmed
2026-07-12; M50).
**Decision:** the consolidated policy lives in one home,
`DESIGN.md § Boundary-fit policy`, as **three behaviors** — *smooth*
(boundary-aware by construction: log-SD for glmmTMB/lme4/lavaan, natural-scale
positive draws for brms), *classed deferral* (the `intraclass_singular_fit`
condition), and *reach-zero* (a boundary draw is kept, or the fixed-rater θ²_r
average is floored at 0) — mapped per engine (fit-time) and per CI method
(interval-time), each cell citing its governing ADR. This entry supersedes the
"case law" status of those ADRs by summarizing them under one policy; the ADRs
stay valid citation targets. It changes **no behavior**: the M50 audit surfaced
no behavior that contradicts its governing ADR, so no gate escalation was
warranted; review (2026-07-12) additionally corrected two documentation gaps in
the first draft — the omitted ADR-023/024 lme4 citations, and the bootstrap
row's under-documented non-convergent-refit warning path — without any code
change. Guard tests in `tests/testthat/test-boundary-policy.R` pin each
documented behavior, each naming its ADR/D-entry (GP7).
**Consequences:** the boundary policy has one authoritative home (DESIGN.md), a
decision record (this entry), and a standing guard-test asset. Any future change
to a documented cell touches the boundary-aware-interval contract
(`PRINCIPLES.md #3`) and requires a new, superseding D-entry — never a silent edit.

### D-005 (2026-07-16): Two-level SEM route to the multilevel estimand is an IP1-fenced parameterization

**Context:** M53's source hunt found no primary source composing two-level SEM
with GT interrater reliability for clustered subjects (Design 1). The published
pieces: the estimand and decomposition (ten Hove et al. 2022, Eqs. 6–7/12–13,
Table 3 — MCMC-estimated); the single-level SEM-GT mean-structure device for
σ²_r (Jorgensen 2021); two-level ML-SEM estimation as generic methodology
(Muthén 1994; Rosseel's lavaan). One-way SEM stays blocked (ADR-014) because
its unsourced approximation targeted a *different* (inexact-in-principle)
quantity.
**Decision (maintainer, M53 gate):** estimating the published Design-1
decomposition via a two-level CFA is an estimation-route parameterization under
IP1's implementation-detail fence — the M5 posture (the lme4 formula was "our
translation of Eq. 7, to be established by oracle, not assumed") — NOT a novel
method. Faithfulness is established numerically: the M53 pilot must show
glmmTMB parity up to documented ML-vs-REML small-sample deltas; systematic
disagreement is a no-go finding, not a tolerance to widen (GP5).
**Consequences:** M53 proceeds to the pilot; the implementation milestone (if
go) inherits this disposition and cites it; the composition ships only with
the oracle evidence attached. A future primary source, if one appears, is
ingested and supersedes the engineering framing.

### D-006 (2026-07-18): M62 GO/NO-GO — transformed bootstrap-t GO, percentile/BCa NO-GO (one-way ICC)

**Context:** M62 assessed whether a non-parametric bootstrap CI for the one-way
random ICC is "not worse" than the package incumbents (Monte-Carlo default,
parametric bootstrap), against a pre-registered coverage-band + width criterion
(GP5), sourced to `ukoumunne2003` and cross-checked against `ohyama2025`. Evidence:
`cairn/references/npbootstrap-oneway-comparison.md`; independent Fable review RR01
(archived) concurs.
**Decision:** **GO** for the `log F` variance-stabilized **transformed
bootstrap-t** — the only method near-nominal (≥ 0.93) at all four cells, faithful
to ukoumunne2003 (RR01 verified eq. 6/7 and reproduced the fixture to 4 dp) and
oracle-validated, and boundary-robust where the glmmTMB MC default aborts
(`intraclass_singular_fit`) on 28–39 % of near-zero-ICC datasets. **NO-GO** for
percentile and BCa (under-cover at C3/C4, as ukoumunne found). M62 ships **no
code**; a future `ci_method = "npbootstrap"` traces to ukoumunne2003 (IP1).
**Framing (RR01 Q3):** the GO does *not* claim to fix the MC default's one-way
boundary defect; a boundary-robust *classical* default (SEARLE exact-F / Burch
REML) is a separate tracked candidate. The bootstrap-t's residual value is
non-normality robustness (ukoumunne Fig. 3) + an interval that exists where the
default aborts.
**Conditions on the implementation milestone (RR01 Q4 / rec 2):** a C4-type corner
cell at n_rep ≥ 2000, lower/upper tail-error tracking, and a pre-specified
below-floor fallback (GP5); balanced-only (unbalanced `n_i`/`n₀` is design work
there).
**Consequences:** percentile/BCa recorded as rejected for this estimand; the
transformed bootstrap-t is cleared to be planned as an exported one-way
`ci_method` (candidate updated with the conditions); the SEARLE-F / Burch-REML
boundary-robust classical CI is added as a candidate.
