# RR01: Review of the M62 GO/NO-GO — non-parametric bootstrap CI, one-way ICC

- **Brief:** `cairn/reviews/RB01-npbootstrap-oneway-go.md`
- **Reviewer:** independent statistical review (Fable), 2026-07-18
- **Materials read:** the synthesis note, both reference notes, both source PDFs
  (ukoumunne2003 §2–§6 incl. eq. 3/6/7, Fig. 1–3, Table I; ohyama2025 note),
  the prototype, the harness, the results fixture, and the package-side code the
  harness exercises (`R/ci-montecarlo.R`, `R/ci-bootstrap.R` abort paths,
  `R/engine-glmmtmb.R` one-way fit).
- **Independent computation performed:** (i) algebraic + numerical check of the
  transform identity and the eq. 7 IJ SE; (ii) a full from-scratch re-run of the
  prototype columns for cells **C4** and **U10** (1000 reps × B=2000 each) using
  the harness's exact seeding; (iii) spot-checks of the MC abort class and the
  parametric-bootstrap boundary behaviour on individual C4 datasets.

## 1. Implementation faithfulness — **correct, faithful to ukoumunne2003**

**(a) Transform and the `f(ρ̂) = log F` claim.** Eq. 6 (p. 3809) is
`f(ρ) = log{[1+(n−1)ρ]/(1−ρ)}`. With `ρ̂ = (F−1)/(F+n−1)` (paper eq. 3;
`data-raw/m62-npbootstrap-prototype.R:51`), substitute:
`1+(n−1)ρ̂ = nF/(F+n−1)` and `1−ρ̂ = n/(F+n−1)`, so `f(ρ̂) = log F` exactly.
Verified numerically: `f(ρ̂) − log F = −2.2e−16`. The back-transform
`logf_to_rho()` (`:66-69`) is the exact inverse `ρ = (f−1)/(f+n−1)` and is
monotone increasing, so quantile back-transformation is order-preserving.

**(b) Eq. 7 IJ SE.** The paper (p. 3811) gives
`SE_IJ(log F) = sqrt( Σ_i [ n_i(ȳ_i•−ȳ••)²/SSA − Σ_j(y_ij−ȳ_i•)²/SSE ]² )`.
The `contrib` vector (`:54-60`) is term-for-term identical (balanced case,
`n_i = n`). Two independent sanity checks pass: the contributions sum to ~0
(2.5e−16; influence values must), and on a test dataset the IJ SE (0.329)
tracks the brute-force bootstrap SD of `log F*` (0.357) — the mild IJ
shrinkage is the known behaviour. A scaling error (e.g. a stray `1/k`) would
have been off by ~3.5×, and would also have destroyed the oracle-check
agreement; there is none.

**(c) Studentized interval.** `t* = (logF* − logF)/SE*_IJ` with the *resample's*
SE (`:93` — correct studentization), interval
`[logF − t*_{.975}·SE_obs, logF − t*_{.025}·SE_obs]` (`:100-102` — correct
quantile reversal), then back-transformed. Standard bootstrap-t, matching the
paper's construction (transformed bootstrap-t with IJ SE, p. 3812).

**(d) Resampling.** `sample.int(k, k, replace = TRUE)` over whole subject
groups (`:90-91`), retaining all `n` observations per selected subject —
§3.1 strategy 1 exactly. Duplicated subjects enter the resampled ANOVA as
distinct clusters, which is the correct strategy-1 treatment.

**Deviations found — all minor, none affecting the verdict:**

- `oneway_anova()` assumes balance (`n <- length(groups[[1]])`, `:43`). Fine
  for M62's balanced scope; eq. 7 supports `n_i` and the transform needs `n₀`
  for unbalanced data — real design work for the implementation milestone, not
  a bug here.
- No guard against degenerate resamples (`SSA = 0 → logF = −Inf`, `SE = 0`).
  Probability is negligible at k ≥ 10 (needs all resampled cluster means
  equal), but an exported implementation needs classed guards (#5).
- The header comment "= REML on balanced data" (`:9`) is true only off the
  boundary; when `ρ̂_ANOVA < 0` REML truncates to 0 and they differ — and that
  is ~39 % of C4 datasets. The *implementation* follows the paper (ANOVA MoM,
  untruncated), which is what IP1 requires; only the comment overstates.
- `quantile()` type-7 interpolation rather than the (B+1) order-statistic
  convention; immaterial at B = 2000.

**Reproduction.** Re-running the prototype columns from scratch with the
harness seeding reproduced the fixture *exactly* (C4: perc/boott/bca =
.864/.934/.890, widths .4118/.5805/.4214; U10: .770/.921/.820, widths
.1817/.3664/.1968). The prototype half of the fixture is fully verified.

## 2. Harness soundness — **sound; conditional MC coverage does not flatter the candidate**

Coverage/width computation is correct: closed-interval containment
(`data-raw/m62-coverage-harness.R:66-71`), per-method width, `colMeans(...,
na.rm = TRUE)` with `n_ok` reported alongside (`:128-130`). The design is
genuinely paired — all five methods see the same `d` per rep (`:94-112`).

**Estimand.** The package's one-way `ICC(1)` is `σ²_subject/(σ²_subject +
σ²_residual)` from `score ~ 1 + (1|subject)` (`R/engine-glmmtmb.R:151-218`,
estimand-spec M6). The DGP has no rater effect, so residual = pure error and
ICC(1) = ρ exactly. The `tidy()` row-match on `index == "ICC(1)"` is correct
(verified against live output). The positional `icc(d, y, subject, rater,
model = "oneway", ...)` call matches the signature.

**MC aborts.** I verified the `n_ok` deficit is what the note claims: in the
first 40 C4 reps, 15 MC failures, *all* classed `intraclass_singular_fit`
(the `R/ci-montecarlo.R:123-133` >1 %-non-finite-draws abort), and all on
datasets with ANOVA `ρ̂ < 0` (range −0.177…−0.014) — i.e. glmmTMB at the
σ²_a = 0 boundary. 15/40 = 37.5 %, consistent with n_ok = 612/1000.
(`icc_ci()` swallows *any* error class as NA, `:42-64`; the spot-check
confirms the deficit is the boundary abort, not something else.)

**Is conditional MC coverage fair?** Yes — and it is the accounting *most
favorable to the incumbent*, hence conservative against the candidate.
Criterion (2)'s bar is `min(incumbents) − .01`: conditioning *raises* MC's
number (C4: .846 conditional vs .518 if aborts counted as failures), which
raises the bar the candidate must clear. Under any harsher treatment of the
aborts the candidate's margin only widens. Note also that criterion (2) was
never binding — the absolute ≥ .93 floor of criterion (1) is what did the
work at every cell, which is exactly the property that keeps the "not worse
than a weak incumbent" comparison from being circular (see Q3). One caveat
for the record: conditional coverage answers "when MC returns an interval, is
it right?" — a different question from operational reliability; publishing
`n_ok` beside it, as the note does, is the right disclosure.

Minor quibble, no action needed: the note's "−0.01 ≈ 2·SE paired" slack is
optimistic (a paired coverage-difference SE at n_rep = 1000 can reach ~.007
when methods disagree on ~5 % of reps), but the criterion is frozen and it
was not the binding constraint anywhere.

## 3. Basis of the GO — **legitimate, with a required framing correction**

The GO is *not* founded solely on beating a boundary-fragile default, for
three reasons:

1. **The absolute floor carries the verdict.** Criterion (1) demands ≥ .93 at
   every cell regardless of the incumbents. The transformed bootstrap-t is, in
   fact, the *only* method of the five that clears .93 at all four cells (MC
   fails C2/C4 at .876/.846; parametric bootstrap fails C3 at .922; perc/BCa
   fail C3/C4). The strongest and most honest statement of the result is
   "the only method in the comparison set that is near-nominal everywhere",
   not "not worse than a broken default".
2. **The method has a published rationale independent of our default's
   fragility.** ukoumunne2003 shows the transformed bootstrap-t holds coverage
   under markedly non-normal cluster effects where the exact analytical (F)
   method degrades (Fig. 3; discussion p. 3816: coverage "never lower than
   3 per cent below the nominal 95"), and Table I shows it is the only
   bootstrap variant with *balanced* tail errors. Those properties are not
   purchasable from SEARLE-F.
3. **The ohyama prior is explained, not refuted.** Against boundary-robust
   classical F/REML CIs on normal data, NBOOT remains slightly worse (wider,
   ohyama §3.2; ukoumunne p. 3816 concedes the width cost). The reversal is
   entirely about *which incumbents exist in this package* — a deployment
   fact, correctly disclosed in the synthesis note.

However, the honest conclusion is **both/and, not either/or**: the pass has
produced clear evidence that the MC default is defective at the one-way
boundary (28–39 % classed aborts *plus* .85–.88 conditional coverage), and a
boundary-robust classical default (SEARLE exact-F for balanced one-way — exact
under normality — or Burch REML) would likely dominate the bootstrap on the
normal cells tested here. The GO must not be recorded in a way that lets the
bootstrap-t stand in for that fix. The synthesis note's "side observation"
should be elevated to a tracked roadmap candidate, and the GO D-entry should
state the bootstrap-t's residual value explicitly (non-normality robustness;
an interval that exists where the default aborts). With that framing: the
recommendation does not change — **GO stands**.

## 4. C4 marginality — **real but tolerable; one wording correction required**

The brief (and my arithmetic) disagree on the margin: at coverage .934 with
n_rep = 1000, SE = √(.934·.066/1000) ≈ .0079, so .934 sits **~0.5 SE** above
the .93 floor, not "~1 SE" as the brief and synthesis note say. Under a flat
prior, P(true coverage < .93) ≈ 30 % — the C4 pass is genuinely marginal and
should be recorded as such, not as a comfortable clear.

Context makes this less alarming than it sounds: the paper's own nearest
corner (k=10, n=10, ρ=.05, Table I) has exact coverage .938, our oracle U10
run gives .921, and the paper's global claim is "never below .92". True
corner-cell coverage in the .92–.94 band is simply what this method does. The
*decision* is robust to that band: even at a true .925, the qualitative case
(near-nominal interval where the default returns nothing 39 % of the time)
is untouched, and M62 ships no code — the implementation milestone's larger
validation re-tests before anything is exported. Deferral is acceptable
**conditional on** the implementation milestone (i) including a C4-type
corner cell at n_rep ≥ 2000, (ii) adding tail-error tracking (see Q5), and
(iii) pre-specifying what happens if the corner lands below floor (label the
limitation or withhold the export — decided before the data, GP5).

## 5. Other statistical concerns

**Parametric-bootstrap over-coverage at C2/C4 is genuine, but degenerate —
and should be annotated.** Mechanism, verified on live C4 datasets: when the
glmmTMB fit hits σ̂²_a = 0, simulate-from-fit generates pure-noise data, and
since the ICC is scale-invariant the resampling distribution of ρ* depends
only on (k, n) — the percentile interval collapses to "the sampling spread of
ρ̂ under ρ = 0", ≈ [0, 0.28] at k=12, n=4. With the harness's fixed
`seed = 1L` this interval is *literally identical* across all boundary
datasets (observed: [0.0000, 0.2830] on three different singular reps). Such
an interval necessarily covers any small true ρ, hence .989/.990 coverage
with narrow median width. This is correct pboot behaviour, not a harness bug
— but the narrow width is an accident of the truth (.05) sitting inside the
ρ=0 sampling spread, not a virtue; the same interval would badly miss a
larger truth, and the method already fails the absolute floor at C3 (.922).
The synthesis note should say this so the .99/.19 rows are not later read as
"pboot is excellent at the boundary". A related blind spot: the harness
records only two-sided coverage; ukoumunne Table I shows how much that hides
(BCa's .834 two-sided at k=10/ρ=.05 decomposes as 2.4 % lower / 14.2 % upper).
Tail-error columns belong in the implementation milestone's harness.

**BCa code** (`m62-npbootstrap-prototype.R:106-120`): standard Efron
formulas; z0 from the empirical proportion (strict `<`, no tie correction —
fine for continuous ρ*), acceleration from the delete-one-cluster jackknife
(the correct resampling unit), zero-denominator guard present. No extreme-z0
guard, but BCa is a reference variant and its observed under-coverage matches
both sources; no concern.

**Negative-ρ̂ handling (no truncation)** matches ukoumunne §5.2 explicitly
("negative estimates of ρ and confidence limits were not truncated") and is
methodologically required for an honest coverage comparison. The
back-transform confines boott endpoints to (−1/(n−1), 1), which is the
estimator's own support. Note the resulting asymmetry with the incumbents
(glmmTMB constrains ρ̂ ≥ 0) is inherent to comparing method families, not a
flaw — each method is scored on its own interval.

## 6. Overall verdict — **concur: GO (transformed bootstrap-t), NO-GO (percentile, BCa)**

The implementation is a faithful, oracle-validated rendering of the published
method (exact eq. 6/7 match; independent full recomputation of C4 and U10
reproduces the fixture to 4 decimals; oracle deltas .014–.017 vs the paper's
exact Table I values, within the pre-registered ±.03). The harness is sound,
the paired comparison fair-to-conservative for the candidate, and the frozen
criterion's absolute floor prevents the weak-incumbent circularity that would
otherwise worry me. Percentile and BCa fail exactly where both sources say
they fail. The GO is justified — provided the D-entry carries the Q3 framing
(bootstrap-t is not the fix for the MC default's boundary defect) and the Q4
conditions on the implementation milestone.

## Beyond the brief

1. **Cell seed collisions (harness `:78`).** `seed_base` depends only on the
   first letter of the cell name plus k+n, so C1/C2 share all data-generation
   seeds (670035…671034) and C3/C4 likewise; C1's and C3's rep-seed ranges
   also overlap. Because `sim_oneway()` scales the same standard normals by
   √ρ/√(1−ρ), C1 and C2 are common-random-numbers coupled. Per-cell coverage
   estimates remain valid and unbiased; only the *joint* "passes at all four
   cells" event has mildly correlated errors. Benign here; worth avoiding in
   the implementation-milestone sweep.
2. **`icc_ci()` swallows every error class as NA** (harness `:42-64`), so
   `n_ok` is an inference, not a measurement, of "boundary abort". My
   spot-check (15/15 failures = `intraclass_singular_fit`) confirms the
   inference at C4; a production harness should record the condition class.
3. **Prototype header comment** "= REML on balanced data" is only true off
   the boundary (see Q1); trivial doc fix if the file is ever touched again.
4. **MC over-coverage at C3 (.980)** — the flip side of the same boundary
   pathology (log-scale draws inflate the interval when σ̂²_a is small but
   nonzero). Strengthens the case that the one-way default deserves its own
   look, independent of the bootstrap question.

## Recommendations

1. **Apply.** Record the GO with the "only method ≥ .93 at every cell"
   framing, scoped to the *balanced* one-way design; note that unbalanced
   support (n_i in eq. 7, n₀ in the transform) is design work for the
   implementation milestone.
2. **Apply.** Correct "~1 SE above the floor" to **~0.5 SE** in the synthesis
   note/D-entry, and make the implementation milestone's validation
   conditions explicit: C4-type corner cell at n_rep ≥ 2000, tail-error
   (lower/upper miss) tracking, and a pre-specified below-floor fallback.
3. **Apply.** Elevate the SEARLE-F / Burch-REML boundary-robust classical CI
   from "side observation" to a tracked roadmap candidate; the GO D-entry
   should state that the bootstrap-t does not resolve the MC default's
   boundary abort/under-coverage defect.
4. **Apply.** Annotate the parametric-bootstrap C2/C4 rows in the synthesis
   note with the degeneracy mechanism (σ̂²_a = 0 → data-independent resampling
   distribution; fixed seed → identical intervals), so the .99-coverage /
   narrow-width cells are not misread as boundary strength.
5. **Consider.** Distinct per-cell seed bases and per-method condition-class
   logging in the implementation-milestone harness (findings 1–2 above).
6. **Reject — re-running at n_rep = 2000 before recording the GO.** The only
   marginal cell (C4) cannot change the decision consequence (M62 ships no
   code; the implementation milestone re-validates with more power), so the
   5–6 h re-run buys nothing the next gate doesn't already provide. The
   maintainer's cut was sound.

**Overall verdict: concur-GO** — transformed bootstrap-t GO / percentile+BCa
NO-GO, with the Q3 framing and Q4 conditions attached to the D-entry.
