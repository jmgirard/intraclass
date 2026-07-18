# RB01: GO/NO-GO for a non-parametric bootstrap CI on the one-way ICC (M62)

- **Date:** 2026-07-18
- **Output required:** write findings to `cairn/reviews/RR01-npbootstrap-oneway-go.md`

You are performing an independent expert statistical review. This brief is
fully self-contained — do not assume any conversation context. Read only what
this brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`intraclass` is an R package computing interrater-reliability ICCs via mixed-model
variance-component estimation, always with a confidence/credible interval. It
currently ships three interval methods: **Monte-Carlo** (default; draws from the
fitted parameter covariance on the engine's log scale — glmmTMB REML), a
**parametric bootstrap** (simulate-from-fit + refit + percentile), and a Bayesian
**posterior** interval (brms).

**Milestone M62** is a *research pass*, not a code-shipping milestone. It asks:
is a **non-parametric (case/cluster) bootstrap** CI "not worse" than those
incumbents, for the **one-way random ICC** (`ρ = σ²_a/(σ²_a+σ²_e)`,
`y_ij = μ + a_i + e_ij`)? It ships **no exported method** — only a GO/NO-GO
recommendation with committed evidence. A GO seeds a *separate* implementation
milestone (which would carry its own, larger coverage validation).

The primary source is **ukoumunne2003** (Statistics in Medicine 22(24):3805–21),
which develops the non-parametric bootstrap for exactly this one-way ICC and finds
that only a **variance-stabilizing transformed bootstrap-t** achieves near-nominal
coverage (the untransformed percentile/BCa under-cover at few clusters). An
independent published comparison, **ohyama2025**, benchmarks methods for this
model and reports the bootstrap as *slightly worse* than classical F/REML CIs,
with REML best overall.

The pass concluded **GO for the transformed bootstrap-t**, **NO-GO for
percentile/BCa** — which *reverses* the ohyama prior. The reversal's stated
reason: ohyama compared the bootstrap to boundary-robust classical F/REML CIs,
but the package's actual default is glmmTMB **MC, which under-covers and outright
aborts (classed `intraclass_singular_fit`) on 28–39 % of near-zero-boundary
datasets** — where the transformed bootstrap-t stays near nominal. This review
is to independently stress-test that conclusion before it is recorded, because it
is surprising and it points toward shipping a new interval procedure (touches the
package's inviolable IP1 "faithful implementer" principle).

## Materials

Read these (repo-relative):

- `cairn/references/npbootstrap-oneway-comparison.md` — the synthesis note: the
  pre-registered "not worse" criterion, the full results table, the oracle
  cross-check, and the draft verdict. **Start here.**
- `cairn/references/ukoumunne2003.md` and the PDF `cairn/references/pdf/ukoumunne2003.pdf`
  (esp. §3.1 resampling strategy, §4 eq. 6 transform, eq. 7 infinitesimal-jackknife
  SE, Fig. 2 coverage).
- `cairn/references/ohyama2025.md` and `cairn/references/pdf/ohyama2025.pdf`
  (§2.3 NBOOT, §3.2 findings).
- `data-raw/m62-npbootstrap-prototype.R` — the prototype implementation
  (`sim_oneway`, `oneway_anova`, `npboot_oneway`, `logf_to_rho`).
- `data-raw/m62-coverage-harness.R` — the coverage/width harness.
- `data-raw/m62-coverage-results.rds` — the results. Read with:
  `r <- readRDS("data-raw/m62-coverage-results.rds")` then inspect
  `r$C4$coverage`, `r$C4$n_ok`, `r$C4$median_width`, etc.

Key results (n_rep=1000; coverage / median width; MC `n_ok`/1000 in parens):

| cell (k,n,ρ) | MC (default) | param.boot | boott (candidate) | perc | bca |
|---|---|---|---|---|---|
| C1 (30,4,.50) | .956/.358 (1000) | .933/.362 | **.940/.369** | .919/.352 | .923/.337 |
| C2 (30,4,.05) | .876/.445 (716) | .990/.188 | **.940/.340** | .918/.293 | .915/.302 |
| C3 (12,4,.50) | .980/.542 (995) | .922/.564 | **.937/.590** | .864/.537 | .878/.482 |
| C4 (12,4,.05) | .846/.679 (612) | .989/.307 | **.934/.580** | .864/.412 | .890/.421 |

Oracle-check (prototype only, ρ=0.05, n=10) vs ukoumunne2003 Fig. 2:
U10/U30/U50 boott = .921/.947/.953 (perc .770/.904/.918; bca .820/.922/.937).

Criterion (frozen before results, GP5): a variant is "not worse" at a cell iff
coverage ≥ 0.93 **and** ≥ min(incumbents) − 0.01; median width breaks ties. GO
iff the primary candidate (transformed bootstrap-t) is not-worse at **every** cell.

## Questions

1. **Implementation faithfulness.** Is `npboot_oneway()` (in
   `data-raw/m62-npbootstrap-prototype.R`) a correct implementation of
   ukoumunne2003's transformed bootstrap-t? Check specifically: (a) the transform
   `f(ρ)=log{[1+(n−1)ρ]/(1−ρ)}` and the claim `f(ρ̂)=log F` (`oneway_anova`);
   (b) the infinitesimal-jackknife SE of `log F`, eq. 7, as coded in the `contrib`
   vector; (c) the studentized interval `logf − tq·se` and back-transform
   `logf_to_rho`; (d) whole-subject resampling. Flag any deviation or bug.
2. **Harness soundness.** Is `data-raw/m62-coverage-harness.R` statistically
   correct? In particular: coverage/width computation, the paired design, that
   `ICC(1)` is the correct estimand (= ρ), and the treatment of MC aborts —
   coverage is computed over `n_ok < n_rep` (conditional). Is using MC's
   *conditional* coverage as "the incumbent coverage" in the criterion fair, or
   does it flatter the candidate?
3. **Basis of the GO.** The candidate's advantage concentrates at the boundary
   cells, where it beats an MC default that fails to return an interval on
   28–39 % of datasets. Is "not worse than a boundary-fragile default" a
   legitimate basis for GO, or is the honest conclusion that the *default* should
   be made boundary-robust (classical SEARLE-F / Burch-REML) instead? Does this
   change the recommendation?
4. **C4 marginality.** boott at C4 is 0.934, ~1 SE above the 0.93 floor at
   n_rep=1000 (a confirmatory n_rep=2000 run was cut for cost; ~5–6 h, boundary
   refits dominate). Is this a material risk to the GO? Is deferring the C4
   firm-up to the implementation milestone's own coverage validation acceptable?
5. **Other statistical concerns.** Is the parametric-bootstrap incumbent's
   boundary behaviour (over-coverage ~0.99 with narrow median width, C2/C4) a
   correct result or a harness artifact? Any concern with the BCa
   z0/jackknife-acceleration code, or with negative-ρ̂ handling (no truncation)?
6. **Overall verdict.** Do you concur with **GO** (transformed bootstrap-t) /
   **NO-GO** (percentile, BCa)? If not, state the verdict and the minimal
   additional evidence that would settle it.

## Constraints

- **M62 ships no code.** The deliverable is a GO/NO-GO recommendation; the GO
  seeds a separate implementation milestone with its own (larger) coverage
  validation. Review the *recommendation*, not production-readiness.
- **IP1 (faithful implementer):** any exported interval procedure must trace to a
  published primary source. ukoumunne2003 supplies it for the transformed
  bootstrap-t. Do not propose shipping an unpublished method.
- **The pre-registered criterion is frozen (GP5)** — do not relitigate its
  thresholds to move the verdict. You *may and should* flag if the criterion is
  methodologically unsound (that is a finding, not a threshold change).
- **n_rep=1000** stands (the 2000 re-run was cut, maintainer decision 2026-07-18).
- If you disagree with any constraint, say so explicitly rather than working
  around it.

## Output format

In `cairn/reviews/RR01-npbootstrap-oneway-go.md`: answer each question by number
with reasoning and evidence (cite file:line where relevant); list any additional
findings under "Beyond the brief"; end with concrete recommendations, each marked
**apply / consider / reject-with-reason**, and a one-line overall verdict
(concur-GO / revise-to-X).
