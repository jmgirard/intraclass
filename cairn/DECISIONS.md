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

### D-007 (2026-07-18): `ORACLES.md` is the declared oracle-registry home; references split

**Context:** `cairn/references/REFERENCES.md` was the pre-migration single page —
1346 lines carrying two different things: a 39-entry oracle→provenance registry
(~94 % of it) and a 16-item bibliography. The validation doctrine requires a repo
with numeric work to *declare* where its oracle records live, in one line of
`DESIGN.md` Conventions; this repo had no such line, and `DESIGN.md § Known
issues` recorded the absence as a standing wart pending the upstream cairn
`ORACLES.md` question (cairn D-024/M42). Meanwhile the cairn source-note
convention (`<citekey>.md` + `INDEX.md`) had already started arriving alongside
it (M62: `ukoumunne2003`, `ohyama2025`), so one directory ran two conventions.
**Decision:** split by *kind*, not by source — the registry becomes
`cairn/references/ORACLES.md` (the **declared registry home**, now named in
`DESIGN.md` Conventions), the bibliography becomes
`cairn/references/BIBLIOGRAPHY.md`, and per-source extractions migrate
progressively into `<citekey>.md` source notes (M64–M67). Explicitly **not** a
file-per-paper shred of the registry: oracle entries are keyed by oracle ID
(`O1`, `O-SEM`, `O-Bayes-IFNML`), tests cite those IDs, and many entries span
several sources — sharding them by citekey would break the ≥2-oracle-types audit
this registry exists to make possible. `REFERENCES.md` is retained as a 6-line
pointer stub, because `cairn/legacy/**`, `CLAUDE_CODE_KICKOFF.md`, and
`data-raw/reviews/` link to it and are entombed documents kept verbatim by
design. The split moved **no numeric value, `Status` line, or citation text** —
verified by byte-identical diffs of both bodies against the original.
**Scope fence:** this settles the *repo* side. Whether cairn itself mandates an
`ORACLES.md` shape stays the upstream open question (cairn D-024); the doctrine
leaves registry *shape* free and requires only that the location be declared, so
this choice is compatible with either upstream outcome and does not pre-empt it.
**Consequences:** the oracle registry has a declared, greppable home and the
`DESIGN.md` known-issue is struck. New oracles register in `ORACLES.md`; new
sources get a `BIBLIOGRAPHY.md` entry plus a `<citekey>.md` note with an
`INDEX.md` line. Citekeys disambiguate same-author-same-year with letter
suffixes ordered by issue (`tenhove2025a` = MBR 60(3) network data,
`tenhove2025b` = MBR 60(5) planned incomplete).
**Also covers `PRINCIPLES.md` #12** (M63 review, 2026-07-18): the split made #12's
`REFERENCES.md` citation path stale, so it now names `BIBLIOGRAPHY.md` — #12 is a
*citation* obligation, and bibliographic detail lives there, not in the oracle
registry (which D-007 keys by oracle ID and reserves for the ≥2-types audit). The
principle's substance is unchanged; only the path moved. `PRINCIPLES.md`'s header
exception list records it as `(#12, D-007)`, per that file's change-control rule.

### D-008 (2026-07-19): Verification bar for the index pages — three entry kinds, and what a script-derived "verified" does not assert

**Context:** `ORACLES.md` (39 entries) and `BIBLIOGRAPHY.md` (38) are the two
`cairn/references/` pages the D-007 split moved as text without reading, and the
last two carrying an unverified extraction status after M69–M71 dated-verified all
30 source notes. They cannot take the source-note bar unchanged: a source note owns
one primary source and is re-read against it, whereas most `ORACLES.md` entries
trace to a committed seeded script under `data-raw/` rather than to a page of a PDF.
M72's implement gate established that no script *output* is committed — `data-raw/`
holds zero `.csv`/`.txt` and one `.rds`, `data-raw/.oracle-*-checkpoint.rds` is
gitignored, 35 of the 41 scripts assert relationships via `stopifnot` rather than
recording values, and only 4 write a committed fixture under
`tests/testthat/fixtures/`.
**Decision:** the bar splits by **entry kind**, three of them.
*Source-traceable* — values trace to a page of a cited source: re-read against the
source itself at the cited page, never against a `<citekey>.md` note, and corrected
in place with the correction cited.
*Script-derived* — values produced by a committed seeded script: confirm the named
script exists, and that the entry's values match an inline expected value in the
script source (hardcoded constant, tolerance target, trailing comment) or a
committed fixture. Where the script commits neither, the entry is recorded as
**script-attested, values not independently confirmed** — the honest status, never
a bare "verified".
*Mixed* — both legs (O1, O-OW, O-SEM and their like): each leg verified by its own
rule, because classifying a mixed entry as a single kind necessarily leaves half its
values unchecked.
**What a script-derived "verified" asserts:** that the registry agrees with what the
repo commits — the script exists, is seeded, and its committed expected values match
the entry. **What it does not assert:** that the script, re-run today, still produces
those values. That is a *reproducibility* claim and requires execution; engine
versions (glmmTMB, brms/Stan), BLAS, and RNG streams may all have drifted since the
entry was written. A script-derived verified status is a **provenance** claim, not a
reproducibility claim, and must not be read as the latter.
**Why re-running was refused (plan gate, 2026-07-19):** the Bayesian sweeps are
multi-hour background jobs (LESSONS 2026-07-19/M47: a live-Stan coverage sweep is
~2 h, roughly doubling under concurrent-R contention), and re-running them is a
different milestone's work with a different risk profile. A discrepancy found by the
confirmation pass is **escalated**, not silently re-run: re-running the implicated
script becomes its own milestone.
**Consequences:** both index pages can reach a dated-verified extraction status that
states what was actually done, closing the last two `references staleness` advisory
survivors. The provenance-vs-reproducibility distinction is now on the record, so a
later reader cannot mistake a script-derived verified entry for a re-executed one.
Reproducibility of the seeded scripts remains a standing, separately-plannable gap
(PRINCIPLES.md #12) — this entry scopes it out, it does not declare it closed.
