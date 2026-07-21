# RR02: npbootstrap exported-API scope — the public string, ICC(k) support, and the reported point (M75)

- **Brief:** `cairn/reviews/RB02-npbootstrap-oneway-api-icck.md`
- **Reviewer:** independent statistical/API review (Fable), 2026-07-21
- **Materials read:** the prototype (`data-raw/m62-npbootstrap-prototype.R`),
  RR01 (archived) §1/§5, D-006 (`cairn/DECISIONS.md:101-128`), the comparison
  synthesis note, the `ukoumunne2003.md` source note, the M75 plan (AC1–AC7),
  `R/icc.R` (`ci_method` validation `:407-410`, roxygen `:283-299`, dispatch
  `:1783-1817`, one-way estimand construction `:1734-1735`, defaults `:375`),
  and `R/estimand.R:62-85` (one-way estimand; divisor semantics `:52-53`).
- **Independent computation performed:** numerical verification (R, 50 draws ×
  n ∈ {2,4,10}) that the Spearman-Brown image of the ANOVA MoM ρ̂ equals
  `1 − 1/F` exactly (max abs. deviation 4.6e−14), plus the pole/monotonicity
  analysis of the composed endpoint map reported under Q2.

Notation: throughout, **k** is the package's rater count per subject (the
estimand divisor, `R/estimand.R:53`) — ukoumunne2003's *n*. The paper's *k*
(cluster count) is written "number of subjects" where needed.

## 1. The exported string `ci_method = "npbootstrap"` — **keep it**

**Recommendation: ship `"npbootstrap"`.** The generality concern is real but
acceptable, for four reasons.

**(a) The string only has to disambiguate within this package's namespace, and
there it is exact.** The existing choice set is `{"montecarlo", "bootstrap",
"posterior"}` (`R/icc.R:409`). The one contrast a user must not miss is against
the incumbent `"bootstrap"`, which is *parametric* (simulate-from-fit + refit,
roxygen `:285-294`). "npbootstrap" names precisely the axis that differs — the
data are resampled (whole subjects), not simulated from the fitted model. That
is the distinction that determines when a user should reach for it (boundary
robustness, no reliance on the fitted model being right).

**(b) The ambiguity the brief worries about can never materialize inside the
API.** The reading "npbootstrap = percentile bootstrap" would only mislead if a
percentile/BCa sibling could ever ship under a nearby name. D-006 records both
as **rejected for this estimand**, permanently — so `"npbootstrap"` will never
need to disambiguate against another non-parametric variant in this package.
The string denotes a family with exactly one member here, and the docs pin
which member.

**(c) The package's `ci_method` strings name families, not algorithms —
consistently.** `"montecarlo"` does not say "log-scale parameter-covariance
simulation"; `"bootstrap"` does not say "parametric percentile". The precise
algorithm has always lived in `@param ci_method`/@details and the ORACLES
registry. `"npbootstrap"` under-specifies to exactly the same degree as its
siblings; a more specific string would be the inconsistency.

**(d) The alternatives are each worse.** `"bootstrap-t"` is misleading in the
more dangerous direction: it fails to signal *non-parametric* and reads as a
variant of the existing parametric `"bootstrap"` (same resampling scheme,
different interval rule) — which it is not. `"npbootstrap-t"` is the most
accurate but breaks the single-lowercase-token lexical convention of the choice
set, and buys precision no user decision needs at call time.
`"transformed-bootstrap"` names the least informative part of the method and
also breaks convention.

The residual risk is scientific-reporting, not API: a user citing
`ci_method = "npbootstrap"` in a paper should report "variance-stabilized
transformed bootstrap-t (Ukoumunne et al., 2003)", not "percentile bootstrap".
That is a documentation duty, and it must be discharged in the `@param` text
itself, not only in @details — see BC1. I also suggest (consider, not binding)
that the printed method label carry the fuller name, e.g.
`non-parametric bootstrap (transformed bootstrap-t)`, so the on-screen output
self-documents.

## 2. ICC(k) via the monotone Spearman-Brown endpoint map — **sound; ship it, with the two mechanical checks below**

### (a) Coverage inheritance — exact, and stronger than the brief assumes

The full endpoint map from the studentized log-F scale to the ICC(k) scale is

`h(logf) = g(ρ(logf))`, with `ρ(x) = (eˣ − 1)/(eˣ + k − 1)` (the prototype's
`logf_to_rho()`, `:66-69`) and `g(ρ) = kρ/(1 + (k−1)ρ)` (Spearman-Brown,
matching the estimand's divisor form `σ²_s/(σ²_s + σ²_res/k)`,
`R/estimand.R:53,62-84`).

Checking every failure mode the brief lists:

- **Monotonicity.** `ρ(x)` is strictly increasing on ℝ (RR01 §1(a) verified the
  inverse pair). `g` has derivative `k/(1 + (k−1)ρ)² > 0` everywhere it is
  defined; its only pole is at `ρ = −1/(k−1)`, which is **exactly the open
  lower boundary of the estimator's support** `(−1/(k−1), 1)` (RR01 §5), never
  attained: any finite `logf` maps to `ρ` strictly interior. So `h` is strictly
  increasing and finite on all of ℝ. No non-monotonicity anywhere on the
  domain the endpoints can occupy.
- **Constant k.** `g` is applied only to the two *final* ρ endpoints, never
  per-resample, so a resample-varying k cannot arise even in principle; and the
  balanced-only scope (AC1 aborts on unbalanced input) makes k a design
  constant equal to the ratings-per-subject count. The true estimand satisfies
  `ICC(k) = g(ρ)` with the *same* fixed g.
- **Endpoint ordering.** Preserved by strict monotonicity;
  `[g(ρ_lo), g(ρ_hi)]` is a valid ordered interval whenever `[ρ_lo, ρ_hi]` is.

With those three facts, coverage inheritance is not merely asymptotic — it is
an **event identity**: for strictly increasing g,
`{ρ_lo ≤ ρ ≤ ρ_hi} = {g(ρ_lo) ≤ g(ρ) ≤ g(ρ_hi)}` realization by realization.
Two-sided coverage, and each tail-error indicator separately, are *identical
random variables* for the ρ interval and the ICC(k) interval — not just equal
in probability. (Width does **not** inherit; see the support point below.)

Two strengthening observations the maintainer should record:

1. **The derived interval is itself a bona fide transformed bootstrap-t
   interval for ICC(k), not a second-class image.** Algebraically,
   `g(ρ̂_MoM) = 1 − 1/F` — I verified this numerically to 4.6e−14 across
   n ∈ {2,4,10} — so the composed map is `h(logf) = 1 − e^(−logf)`. The
   ICC(k) endpoints are the same studentized log-F pivot back-transformed
   through a different (still monotone) inverse. `1 − 1/F = (MSA − MSE)/MSA`
   is exactly the classical ANOVA ICC(k) estimator, and `(−∞, 1)` is that
   estimator's own support — so the untruncated-endpoint doctrine (RR01 §5,
   "confined only to the estimator's own support") carries over verbatim.
2. **This is already the package's doctrine, not an innovation.** The
   incumbent MC/bootstrap paths obtain ICC(k) intervals by pushing each
   draw/resample through the estimand reducer and taking quantiles; since
   quantiles commute with monotone maps, transform-then-quantile and
   quantile-then-transform coincide. npbootstrap's endpoint mapping is the
   same monotone-equivariance assumption every existing `ci_method` relies on
   for `unit = "average"`.

One user-facing consequence to document (BC4): near the boundary the ICC(k)
lower endpoint can be **markedly** negative — `g` sends `ρ_lo → −1/(k−1)⁺` to
−∞ (e.g. ρ_lo = −0.33 at k = 4 maps to ≈ −∞-adjacent values; a plausible C4
ρ_lo of −0.25 maps to −4.0). This is method-faithful (it is the ANOVA ICC(k)
estimator's own scale), but a user seeing `ICC(k) ∈ [−4.0, 0.6]` deserves one
sentence of explanation.

### (b) IP1 — the argument alone does not meet the bar; the argument plus two constructible numeric checks does

Plainly: **there is no published oracle** for the ICC(k) transformed
bootstrap-t interval — ukoumunne2003 tabulates ρ only (Table I's four methods,
source note `:129`), and ohyama2025 likewise. So a shipped ICC(k) interval
cannot cite an external Table-I-style anchor of its own.

But an oracle is **constructible**, in two independent pieces:

- **Oracle A (algebraic cross-derivation, machine precision).** The identity
  `g(ρ endpoint) = 1 − e^(−logf endpoint)` gives a second, algebraically
  independent code path to the same numbers: one route composes
  `logf_to_rho()` then Spearman-Brown with the estimand divisor `k_eff`; the
  other never touches ρ at all. Agreement to ~1e−12 verifies the
  implementation *and* — because the `1 − e^(−logf)` route uses the data's
  ratings-per-subject n while the SB route uses the estimand's `k_eff` — it
  simultaneously verifies the design-consistency condition `k_eff = n` that
  the whole construction assumes. A divisor bug, a per-resample application
  of g, or a swapped endpoint all break it.
- **Oracle B (inherited empirical anchor).** Because coverage is an event
  identity, the Table I anchors (0.938/0.944/0.9395 ± .03) are *provably* also
  the exact-coverage anchors for the ICC(k) interval. The n_rep ≥ 2000 sweep
  should therefore add an ICC(k) coverage column (truth = `kρ/(1+(k−1)ρ)` per
  cell) and assert it equals the ICC(1) column **rep-by-rep** (zero
  tolerance). This is not a new Monte-Carlo experiment — it is a mechanical
  check that the shipped code realizes the identity the proof relies on; any
  discrepancy is an implementation bug by construction.

Is this IP1-satisfying? My judgment: it is an **acceptable, principled
extension** of IP1, not a bypass — with the extension named honestly. IP1's
two-oracle rule exists to catch wrong derivations and wrong code. Here the
derivation risk is discharged by a two-line exact proof (monotone
reparameterization; no asymptotics, no approximation — the same epistemic
grade as RR01's verification that `f(ρ̂) = log F`), and the code risk is
discharged by Oracles A and B above, which are numeric, independent, and
strict. What the package must *not* do is record the ICC(k) interval in
ORACLES.md as if it had its own external anchor; the registry entry must state
the basis as "exact monotone-map inheritance from the ICC(1) oracle, plus the
identity cross-check" (BC4). Shipping on that recorded basis is sound.
Shipping on the *argument alone*, without Oracles A and B wired into tests and
the sweep, would fall short of IP1 and I would not endorse it.

### (c) Recommendation — ship via Spearman-Brown

**Ship ICC(k)** (option 1), with the validation and documentation duties of
BC2–BC4. Reject option 3 (withhold + abort on `unit = "average"`): it would
make the bare default call (`unit = c("single", "average")`, `R/icc.R:375`)
abort, a hostile ergonomic for the package's most common invocation, and there
is no statistical uncertainty to justify it — the inheritance is exact, not
approximate. Option 2 ("ship with explicit caveat") collapses into option 1:
the required documentation (BC4) is a description of the construction and its
untruncated support, not an expression of doubt about coverage.

Scope caveat carried forward: the pole/support analysis above is
**balanced-only**. An unbalanced extension replaces k with n₀ in the transform
and changes the estimator's support, so the monotone-map argument must be
re-derived there — this belongs in the unbalanced candidate row (see Beyond
the brief, finding 2).

## 3. The reported point — **concur: report the engine REML point**

The maintainer's recommendation is correct. Four grounds:

**(a) The package contract.** `ci_method` selects the *interval* method; the
point estimator is package-level and engine-owned. Every existing method flows
through the shared `icc_point(engine_fit$components, e)` path
(`R/icc.R:1795-1799`); even the Bayesian branch, which deviates, does so for a
principled transform-invariance reason (ADR-033) and still keeps the point
tied to its own machinery, not to a second frequentist estimator. A user who
switches `ci_method` to compare intervals must see the point held fixed —
otherwise the switch appears to change the *estimand*.

**(b) The package's identity.** The public claim (CLAUDE.md, DESIGN) is
"modern mixed-model variance-component estimation, not classical ANOVA mean
squares". Surfacing an ANOVA-MoM point under exactly one `ci_method` would
leak a second estimator into the API and contradict the package's stated
contract. The MoM ρ̂ is interval machinery — an internal pivot ingredient with
the same status as the MC method's log-scale draws — and internal machinery
does not surface.

**(c) The divergence is confined to the boundary and is the smaller
incoherence.** On non-boundary balanced data the two estimators coincide
exactly, so the choice is invisible. At the boundary (~39 % of C4-type
datasets, RR01 §2), the alternatives are: (i) REML point 0 beside an interval
whose lower endpoint dips below 0 — the standard, well-understood picture for
a boundary-respecting estimator paired with an untruncated interval (it reads
correctly as "the data are consistent with values near and below zero; the
constrained estimate sits at the boundary"); or (ii) a *negative point
estimate* of a nonnegative population parameter, which flips sign against
`montecarlo` on the same data and against every published output of this
package. (i) is routine in variance-component practice; (ii) is a support
violation of the estimand (the population ICC(1) is in [0, 1)) presented as a
point estimate. RR01 §5 already recorded the ρ̂ ≥ 0 vs untruncated-interval
asymmetry as "inherent to comparing method families, not a flaw"; the same
disposition applies inside the output object.

**(d) The one genuine cost is bounded and measurable.** With the REML point,
there is a small boundary-adjacent event where the point falls *outside* the
interval: point 0 above an entirely-negative interval (`ρ_hi < 0`). When the
true ρ > 0 this event is a subset of the upper-tail misses the sweep already
tracks (interval entirely below 0 < ρ ⇒ truth beyond the upper endpoint), so
its rate is bounded by the recorded upper-tail error — a few percent at the
near-zero cells, ~0 elsewhere. (The converse escape, point below the interval,
requires REML = 0 with an all-positive interval, which needs `t*_{.975} < 0` —
practically impossible.) The bootstrap-t construction never guaranteed
point-containment anyway, even for its own MoM center. The sweep should record
this rate per cell (BC6) and @details should carry one sentence on the
boundary picture (BC5). Neither observation changes the recommendation.

Note also the pleasant one-way-balanced consistency check this choice enables:
off the boundary, the reported REML point must *equal* the interval's internal
MoM ρ̂ (up to optimizer tolerance) — a free cross-estimator parity assertion
for the test suite (consider, recommendation 5).

## Beyond the brief

1. **The `g(ρ̂) = 1 − 1/F` identity is worth recording in the source
   note/ORACLES entry.** It shows the ICC(k) interval is not a derived
   afterthought but the same log-F pivot back-transformed through the ANOVA
   ICC(k) estimator's own inverse `h(logf) = 1 − e^(−logf)` — and it supplies
   the free second derivation that Oracle A (BC2) needs. Verified here to
   4.6e−14.
2. **The unbalanced candidate row should inherit a warning from Q2.** The
   Spearman-Brown pole sits exactly at the balanced support boundary
   `−1/(k−1)`; with unbalanced data the transform's group-size constant
   becomes n₀ and the MoM estimator's support changes, so the
   monotone-map/pole alignment must be re-derived, not assumed. One sentence
   in the candidate row prevents a silent future carry-over.
3. **The identity test doubles as a design-consistency guard.** Because the
   `1 − e^(−logf)` route uses the data's ratings-per-subject while the SB
   route uses the estimand's `k_eff` divisor (`R/estimand.R:53`), BC2 fails
   loudly if the one-way dispatch ever wires a `k_eff` that differs from the
   observed group size — a class of bug no coverage sweep would catch (the
   sweep's truth uses the same k as the code under test).
4. **Roxygen `@param ci_method` (`R/icc.R:283-299`) currently enumerates
   engine availability per method.** The npbootstrap addition must state its
   availability envelope in the same style (balanced one-way only; any
   engine's fit is bypassed for the interval since the reducer works on raw
   data — whichever wording T3 lands on, the restriction belongs in `@param`,
   not only @details, to match the established pattern).

## Recommendations

1. **Apply.** Ship the string `"npbootstrap"` (Q1); discharge the
   naming-precision duty in the `@param ci_method` text per BC1.
2. **Apply.** Ship ICC(k)/`unit = "average"` via the monotone Spearman-Brown
   endpoint map, with the identity cross-check test (BC2), the sweep's
   rep-by-rep inherited-coverage assertion (BC3), and the documentation +
   ORACLES basis statement (BC4).
3. **Apply.** Report the engine REML point for both estimands under
   npbootstrap, unchanged from every other `ci_method` (BC5); record the
   point-outside-interval rate in the sweep (BC6).
4. **Consider.** Carry the fuller method label into the printed output
   (e.g. `non-parametric bootstrap (transformed bootstrap-t)`) so the
   on-screen result self-documents the variant.
5. **Consider.** Add an off-boundary parity test asserting the reported REML
   point equals the reducer's internal MoM ρ̂ on balanced one-way data (they
   coincide analytically; tolerance ~1e−4 for optimizer convergence).
6. **Consider.** Add the unbalanced-extension warning sentence (finding 2) to
   the unbalanced candidate row when M75's tracking updates land.
7. **Reject — renaming to `"bootstrap-t"`, `"npbootstrap-t"`, or
   `"transformed-bootstrap"`.** Each is worse than `"npbootstrap"`:
   `"bootstrap-t"` obscures the parametric/non-parametric axis (the one that
   matters against the incumbent `"bootstrap"`), and the hyphenated forms
   break the choice-set convention while buying precision the docs already
   deliver (Q1).
8. **Reject — withholding ICC(k) (abort on `unit = "average"`).** The
   inheritance is an exact event identity, not an approximation; aborting the
   package's default call would impose a real ergonomic cost to hedge against
   no identified statistical risk (Q2c).

## Binding criteria

- BC1: The exported string is `"npbootstrap"`, and the `@param ci_method`
  roxygen entry names the exact variant — subject (cluster) resampling with
  the `log F` variance-stabilized **transformed bootstrap-t** and
  infinitesimal-jackknife SE, citing Ukoumunne et al. (2003) — and states
  explicitly that it is **not** a percentile bootstrap (percentile and BCa
  were assessed and rejected, D-006).
- BC2: A committed test verifies, on the M62 parity datasets, that the
  ICC(k)/`unit = "average"` interval endpoints computed via the shipped
  Spearman-Brown route equal `1 − exp(−(log F endpoint))` computed directly
  from the studentized log-F endpoints, with max absolute deviation
  ≤ 1e−10.
- BC3: The n_rep ≥ 2000 sweep records ICC(k) coverage per cell against the
  true `kρ/(1 + (k−1)ρ)` and asserts the ICC(k) coverage indicator equals the
  ICC(1) coverage indicator **rep-by-rep** (tolerance: exact equality, zero
  discrepant reps); any discrepancy halts the sweep as an implementation bug.
- BC4: `?icc` @details states that the npbootstrap ICC(k) interval is the
  exact monotone Spearman-Brown image of the ICC(1) interval (coverage
  identical by construction), that its endpoints are untruncated with support
  `(−∞, 1)`, and that the lower endpoint can be markedly negative near the
  boundary; the ORACLES.md entry records the ICC(k) validation basis as
  "exact monotone-map inheritance from the ICC(1) Table I anchor + the BC2
  identity cross-check", not as an independent external anchor.
- BC5: The reported point estimate under `ci_method = "npbootstrap"` is the
  engine (glmmTMB REML) point via the shared `icc_point()` path for both
  ICC(1) and ICC(k), identical to every other frequentist `ci_method` on the
  same fit; the ANOVA-MoM ρ̂ is never surfaced as a point estimate. @details
  documents that at the σ²_a = 0 boundary the point reads 0 while the
  untruncated interval may extend below 0, and that this signals boundary
  proximity.
- BC6: The sweep records, per cell, the frequency of the reported (REML)
  point lying outside the npbootstrap ICC(1) interval; at every cell with
  true ρ > 0 this rate must not exceed that cell's recorded upper-tail-error
  rate (an exact logical bound; tolerance 0), and the observed rates are
  reported in the committed fixture.
