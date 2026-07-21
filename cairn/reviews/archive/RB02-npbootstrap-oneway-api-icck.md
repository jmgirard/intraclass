# RB02: npbootstrap exported-API scope — the public string, ICC(k) support, and the reported point (M75)

- **Date:** 2026-07-21
- **Output required:** write findings to `cairn/reviews/RR02-npbootstrap-oneway-api-icck.md`

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`intraclass` is an R package that computes interrater-reliability intraclass
correlation coefficients in the generalizability-theory framework, using
mixed-model variance-component estimation with boundary-aware Monte-Carlo
confidence intervals. Its user entry point is `icc()`; the interval method is
chosen with `ci_method` (currently `"montecarlo"` (default), `"bootstrap"` (a
parametric bootstrap), and `"posterior"` (Bayesian)).

Milestone **M75** exports a fourth interval method: the ukoumunne2003
variance-stabilized **transformed bootstrap-t** for the **balanced one-way
random** ICC, as `ci_method = "npbootstrap"`. The method resamples whole
subjects with replacement, computes a one-way ANOVA on each resample, applies
the `log F` variance-stabilizing transform (ukoumunne2003 eq. 6), uses the
infinitesimal-jackknife SE (eq. 7) to studentize, and back-transforms the
studentized endpoints to the ICC scale. The point estimate it targets is
`ρ = ICC(1) = σ²_subject / (σ²_subject + σ²_residual)`.

A prior GO/NO-GO assessment (milestone M62) and an independent Fable review
(RR01, archived) established the method as faithful to the source and
oracle-validated, and chose it (GO) over the percentile and BCa bootstrap
variants (NO-GO). D-006 recorded that decision, including the exported string
`"npbootstrap"`. M75 is now implementing the exported method.

Three implementation-gate decisions have surfaced that a maintainer flagged as
needing independent statistical/API review before they ship (they fall in the
"irreversible exported-API" and "no available oracle" review categories). This
brief poses those three questions. It does **not** re-open the GO/NO-GO
decision, the untruncated-endpoint decision, or the balanced-only scope — those
are fixed (see Constraints).

## Materials

Read these; line numbers are anchors, read enough surrounding context to be sure.

- **The reducer prototype to be ported:** `data-raw/m62-npbootstrap-prototype.R`
  — `oneway_anova()` (`:41-63`), the `log F` transform / inverse
  `logf_to_rho()` (`:66-69`), the studentized bootstrap-t construction
  (`:99-103`). This is the RR01-verified reference implementation.
- **The prior Fable review:** `cairn/reviews/archive/RR01-npbootstrap-oneway-go.md`
  — especially §1(a)–(d) (transform / eq. 7 SE / studentization faithfulness)
  and §5 (negative-ρ̂ handling, **no truncation**, and the estimator's support
  `(−1/(n−1), 1)`).
- **The governing decision:** `cairn/DECISIONS.md` D-006 (`:101-128`).
- **The comparison synthesis note:** `cairn/references/npbootstrap-oneway-comparison.md`.
- **The primary source note:** `cairn/references/ukoumunne2003.md` (the eq. 6/7
  extractions and the Table I exact-coverage anchors).
- **The milestone plan and its acceptance criteria:**
  `cairn/milestones/M75-npbootstrap-oneway-cimethod.md` (AC1–AC7).
- **The dispatch site the exported method wires into:** `R/icc.R` — the
  `ci_method` interval branch (`:1783-1817`), the one-way estimand construction
  (`:1734-1735`), and the point-estimate computation `icc_point(engine_fit$components, e)`
  (`:1795-1799`). Note the default `unit = c("single", "average")` (`:375`).
- **The estimand definition** for one-way ICC(1) and ICC(k):
  `R/estimand.R:62-84`. The point reducer computes `signal / (signal + error/divisor)`,
  so ICC(k) uses divisor `k` and equals `σ²_s / (σ²_s + σ²_res/k)`.

## Questions

**1. The exported public string `ci_method = "npbootstrap"`.**
This string is an irreversible API commitment: once released, changing it needs
a deprecation cycle. D-006 fixed it, but the method that GO'd is specifically
the **log-F transformed bootstrap-t with an infinitesimal-jackknife SE** —
while the percentile and BCa bootstraps (equally "non-parametric bootstrap"
methods) were explicitly NO-GO. Is `"npbootstrap"` an apt, non-misleading
public name, or does it over-claim generality (a user could reasonably read
"npbootstrap" as a percentile bootstrap, the variant that was rejected)? Weigh
keeping `"npbootstrap"` against a more specific string (e.g. `"bootstrap-t"`,
`"npbootstrap-t"`, `"transformed-bootstrap"`). Recommend the string to ship; if
you recommend keeping `"npbootstrap"`, state why the generality concern is
acceptable.

**2. ICC(k) / `unit = "average"` support via a monotone Spearman-Brown map.**
ukoumunne2003 defines and validates the method only for `ρ = ICC(1)`. But a
default `icc()` call requests **both** ICC(1) and ICC(k), where ICC(k) is the
reliability of the mean of the k ratings,
`ICC(k) = σ²_s / (σ²_s + σ²_res/k) = kρ / (1 + (k−1)ρ)`, a monotone-increasing
function of ρ. The maintainer has decided to **also emit an ICC(k) interval by
mapping the two ρ endpoints through this transform**:
`[ICC_k(ρ_lo), ICC_k(ρ_hi)]`.
  - **(a)** Does the coverage of this ICC(k) interval equal the coverage of the
    underlying ρ interval, by the invariance of interval coverage under a
    monotone reparameterization? The full endpoint map is a composition of
    monotone maps (studentize on the log-F scale → back-transform to ρ →
    Spearman-Brown to ICC(k)); confirm nothing in that composition breaks the
    coverage-inheritance argument (e.g. non-monotonicity, a `k` that varies
    across resamples, endpoint ordering).
  - **(b)** IP1 (oracle-first) requires a shipped numeric result to agree with
    ≥2 independent oracles. Is there a published or constructible oracle for the
    ICC(k) npbootstrap interval, or does it ship on a coverage-inheritance
    *argument* rather than an independent numeric check? Does the monotone-reparam
    argument satisfy the IP1 bar, extend it acceptably, or bypass it? Say plainly
    whether shipping ICC(k) on that basis is sound.
  - **(c)** Recommend one: ship ICC(k) via Spearman-Brown (and state how to
    validate and document it), ship-with-explicit-caveat, or withhold it
    (restrict npbootstrap to ICC(1) and abort with a classed error when
    `unit = "average"` is requested — which would make the bare default call
    abort until the user sets `unit = "single"`).

**3. The reported point estimate under npbootstrap.**
The interval is built from ukoumunne's ANOVA method-of-moments ρ̂, which is
untruncated and can be negative at the boundary. Every other `ci_method`
reports the engine (glmmTMB REML) point, clamped to ≥ 0. On non-boundary
balanced data the two coincide exactly; at the boundary (~39% of the near-zero
small-k corner cell, RR01 §2) REML reads 0 while ANOVA-MoM ρ̂ is negative. The
maintainer's session **recommends reporting the engine REML point** (≥ 0,
consistent with every other method; `ci_method` conventionally changes only the
interval, not the point). Do you concur, or should the reported point match the
interval's estimator (ANOVA-MoM ρ̂, method-faithful but negative-capable,
diverging from `montecarlo` on the same data)? Address the user-facing
coherence of a point of 0 sitting beside an untruncated interval whose lower
endpoint dips below 0.

## Constraints

Fixed; do not relitigate. Flag disagreement explicitly rather than working
around it silently.

- **D-006:** GO for the transformed bootstrap-t; NO-GO for percentile and BCa;
  **balanced-only** (unbalanced `n_i`/`n₀` is deferred design work, a separate
  candidate). IP1 oracle-first governs.
- **RR01 §5 (untruncated endpoints):** the ρ interval is **not** truncated to
  [0,1] — it is confined only to the estimator's own support `(−1/(n−1), 1)`.
  This is required for coverage fidelity and to match the Table I oracle. Do
  **not** propose truncating the ρ interval. (Whether the *derived* ICC(k)
  interval or the reported point is separately clamped is in scope — questions
  2 and 3 — but the ρ interval itself is settled.)
- **The ICC(1) external oracle stands and is not in question:** ukoumunne2003
  Table I exact transformed-bootstrap-t coverage at (k∈{10,30,50}, n=10, ρ=.05)
  is 0.938 / 0.944 / 0.9395, matched within a pre-registered ±0.03 by the M75
  sweep. This brief concerns only the API string (Q1), the ICC(k) extension
  (Q2), and the reported point (Q3).
- Balanced one-way random design only.

## Output format

In `RR02-npbootstrap-oneway-api-icck.md`: answer each question by number with
your reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked
apply / consider / reject-with-reason. Where a finding binds implementation
(e.g. a required abort, a mandated doc caveat, a validation the sweep must add),
also emit a `## Binding criteria` section: numbered `BC1…`, each a measurable
assertion checkable against evidence, with any numeric projection stating its
tolerance. These are ingested VERBATIM into M75's acceptance criteria and
mechanically diffed against this file; departures are legal only through M75's
shown "Deviations from RR02" table.
