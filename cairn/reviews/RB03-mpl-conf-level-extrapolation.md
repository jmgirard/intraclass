# RB03: Soundness of MPL κ_m extrapolation to conf_level 0.99 (α=0.01) and the sub-0.6 ρ region (M90)

- **Date:** 2026-07-24
- **Output required:** write findings to `cairn/reviews/RR03-mpl-conf-level-extrapolation.md`

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`intraclass` is an R package computing interrater-reliability ICCs via
mixed-model variance components with boundary-aware Monte-Carlo confidence
intervals. One exported CI method, `ci_method = "mpl"`, is the **modified
profile-likelihood (MPL) interval of Xiao & Liu (2013)** (Comput Stat
28:2241–2265; source notes in `cairn/references/xiao2013.md`) for the
**balanced-complete two-way random absolute-agreement ICC(A,1)** (and its
Spearman-Brown images ICC(A,k)/ICC(A,m)). It currently ships **at conf_level
0.95 only**.

The MPL interval is `CI = { ρ : D(ρ) ≤ (1+κ_m)·χ²_{1,1−α} }`, where `D(ρ)` is
the profile deviance and **κ_m is a per-(R,S)-geometry correction constant**
that makes the interval cover at nominal. κ_m has **no closed form**: it is
calibrated by Monte-Carlo. The calibration (see Materials) is a Bartlett-type
MC estimator, `κ_corr(ρ,δ) = quantile_{1−α}(D(ρ_true)) / χ²_{1,1−α} − 1`,
maximized over a (ρ,δ) grid per geometry: `κ_m = max κ_corr`.

**The oracle situation (crux of this review).** xiao2013's *published* κ_m
table (Table 3 δ_U=16 column; Table 6's two-sided values 0.32, 0.52, 0.67,
0.13, 0.23, 0.33) is at **90% two-sided (α=0.10)** and over **ρ ∈ [0.6, 0.9]
only** (its ρ_L=0.6 fence). The package's from-scratch MPL machinery was
oracle-validated against exactly this table at milestone M86. So:

- The **shipped conf_level 0.95** (α=0.05) κ_m has **no external oracle** — it
  is an extrapolation in α from the α=0.10-validated machinery, accepted (D-014
  condition (i), D-015) on the basis of *simulated coverage only*.
- Milestone M90 now adds **conf_level 0.90 (α=0.10)** and **conf_level 0.99
  (α=0.01)**. conf_level **0.90 regains a direct external oracle** over ρ≥0.6
  (it *is* xiao2013's published level). conf_level **0.99 does not** — α=0.01 is
  a *deeper-tail* extrapolation than the already-shipped 0.95, with no published
  table anywhere.
- Both new levels also extend below ρ=0.6 (down to ρ=0.05, the near-zero σ²_s→0
  boundary), which has **no external oracle at any α**.

M90 proposes to validate the extrapolated κ_m by its **defining coverage
property** (the M86 doctrine: "validate a calibration constant by the interval
it builds covering at nominal", not by reproducing the constant) via a
pre-registered coverage sweep. Before committing multi-hour calibration +
coverage-sweep compute and before exporting conf_level 0.99 (milestone M91),
the maintainer wants an independent statistical judgment on whether this
extrapolation is sound and adequately validated.

## Materials

Read these (repo root = `intraclass`):

- **`cairn/references/xiao2013.md`** — the primary source notes. Key facts: the
  interval Eq. (9) p. 2245; the κ_corr / κ_m calibration Eqs. (11)–(13),
  pp. 2247–2251; the "Tables at a glance" section (all two-sided tables are 90%,
  α=0.10); the transcribed Table 4/6 anchor cells; the Table 9 κ_m erratum.
- **`data-raw/m86-mpl-lib.R`** — the from-scratch reference implementation.
  Especially `mpl_kappa_corr()` (lines 160–202: the Bartlett-type MC estimator,
  including the side-specific signed-root fix, M86 review Finding 2) and
  `mpl_kappa_m()` (lines 204–237: the grid max), `mpl_deviance`/`mpl_fit`
  (lines 90–128), `mpl_interval` (lines 130–158), `mpl_simulate` (line 248).
- **`data-raw/m88-mpl-kappa-table.R`** — the shipped-table generator: the
  **scan (n_mc_scan=1500) → top-3 re-evaluation (n_mc_final=6000) → max**
  bias-correction (lines 12–38 header + body), at `alpha_pass = 0.05`, over the
  grid `R = 2:10`, `S ∈ {10,15,20,30,50,100}`, `ρ ∈ [0.05,0.9]`, `δ = 2^{−1:4}`.
- **`R/ci-mpl.R`** — the runtime deterministic interval + κ_m lookup
  (`mpl_kappa_lookup`, lines 204–233; the reducer `mpl_ci`, lines 242–260).
- **`cairn/references/mpl-twoway-random-comparison.md`** — M87's pre-registered
  coverage criterion (§ "Pre-registration", lines 182–256) and GO/NO-GO verdict
  at α=0.05 (the 5 decisive cells C1–C5; the 0.93 = nominal−2pp floor).
- **`cairn/DECISIONS.md`** — D-014 (M87 GO-for-opt-in + conditions (i)–(iii)),
  D-015 (M88 export scope), D-016 (M89 numeric unit).
- **`cairn/milestones/M90-mpl-conf-level-calibration.md`** — the milestone this
  review gates (its AC1/AC4 already reflect the 0.90 external-oracle finding).

The proposed M90 GO/NO-GO criterion (frozen only after this review): at each
level c ∈ {0.90, 0.99}, MPL is "adequate at a cell" iff empirical coverage
**≥ c − 0.02** at every M87 cell (C1–C5, C2/C3 the near-zero/few-subjects
boundary cells, decisive); MPL-only (no incumbent re-comparison — settled
method-level at D-014); over-coverage passes; median width reported for context.

To reproduce a κ_corr value: `source("data-raw/m86-mpl-lib.R")`, then e.g.
`mpl_kappa_corr(rho=0.6, delta=16, n_r=3, n_s=50, alpha=0.10, side="two", n_mc=6000)`
should be ≈ 0.67 (xiao2013 Table 3/6). Try `alpha = 0.01` to see the deep-tail behavior.

## Questions

1. **Deep-tail validity of the MPL adjustment.** The MPL correction is a
   first-order (Bartlett-type) adjustment scaling the χ² critical value. At
   α=0.01 the governing critical value is χ²_{1,0.99} (deep in the upper tail).
   Is there a known reason the single multiplicative constant κ_m becomes an
   inadequate parameterization of the correction as α→0 — i.e. does the true
   correction to the profile-deviance reference distribution become shape- (not
   just scale-) dependent in the extreme tail, so that one κ_m calibrated to the
   0.99 deviance quantile does not deliver 0.99 coverage as reliably as at
   α∈{0.05,0.10}? If so, what is the practical magnitude for the geometries here
   (R∈2:10, S∈10:100)?

2. **MC estimation of a 0.99 tail quantile.** `κ_corr` at α=0.01 requires the
   0.99 quantile of the simulated deviance `D`. This is noisier than the 0.95/0.90
   quantiles the shipped table uses, and κ_m = max over a grid compounds an
   upward winner's-curse bias (the M88 scan→top-3-at-n_mc=6000 procedure was
   tuned for α=0.05). For a trustworthy α=0.01 κ_m: (a) what MC sample size and
   bias-correction (more top-k cells? tail-model extrapolation instead of a raw
   empirical quantile? larger n_mc?) do you recommend, and (b) is the empirical
   0.99 quantile even the right estimator, or should the deep tail be modeled
   (e.g. a smooth fit to the deviance CDF)?

3. **Coverage-only validation adequacy.** Is validating the extrapolated κ_m by
   its defining coverage property (interval covers ≥ c−0.02 across the decisive
   cells) an *adequate substitute* for an external oracle at α=0.01 and in the
   sub-0.6 ρ region — or can coverage land at nominal while something else is
   wrong (interval systematically mis-located/asymmetric, pathological width,
   non-monotone behavior in ρ)? What additional diagnostic, if any, should the
   sweep record to close that gap?

4. **Sub-0.6 ρ / near-zero boundary.** Both new levels extrapolate down to
   ρ=0.05 (σ²_s→0), where the incumbent MC default aborts and κ_m grows large.
   Is the MPL interval + κ_m calibration subject to any known failure mode in
   this regime that the ρ≥0.6 oracle does not exercise (e.g. the σ²_s boundary
   pile-up distorting the deviance reference, or κ_corr's grid-max being
   dominated by an unstable near-zero cell)? Does this differ between α=0.10 and
   α=0.01?

5. **Criterion sufficiency.** Is the proposed GO/NO-GO criterion (coverage ≥
   c−0.02 at C1–C5, MPL-only, over-coverage passes) statistically sound and
   sufficient to authorize *exporting* conf_level 0.99? Would you require any
   additional cell (e.g. a higher-S or higher-R stress cell specific to the deep
   tail), a two-sided coverage band (to catch gross over-coverage/width blowup),
   or a minimum n_rep for the 0.99 coverage MC-SE?

6. **Go / no-go on 0.99 at all.** Weighing questions 1–5: is exporting a *no
   external oracle*, deep-tail (α=0.01) MPL interval defensible on
   simulated-coverage evidence alone (as the already-shipped 0.95 is), or should
   conf_level 0.99 be held back (kept a candidate) while 0.90 — which has the
   direct xiao2013 oracle — proceeds? State the conditions under which 0.99 would
   be exportable.

## Constraints

Fixed; do not relitigate (flag explicit disagreement rather than working around):

- **D-014:** MPL is GO-for-opt-in at conf_level 0.95; the method-level "not worse
  than the MC/parametric-bootstrap incumbents" verdict is settled. This review is
  about *extending the confidence level*, not re-opening whether MPL ships.
- **D-015:** exported as a deterministic `ci_method = "mpl"` with a precomputed
  κ_m table and loud aborts off the supported grid; ICC(A,k)/ICC(A,m) via the
  Spearman-Brown image. The deterministic-closed-form character is fixed.
- The **estimand** (balanced-complete two-way random absolute-agreement ICC(A,1),
  Gaussian), the from-scratch machinery in `data-raw/m86-mpl-lib.R`, and its
  α=0.10 oracle validation against xiao2013 (M86) are fixed and correct.
- The **level set {0.90, 0.95, 0.99}** and the **two-milestone split** (M90
  calibrate+verdict; M91 export) are fixed. Unbalanced/incomplete, fixed-rater,
  and consistency designs are out of scope (separate candidates).
- The accepted posture that an extrapolated κ_m may be established by simulated
  coverage where no oracle exists (D-014(i)) is a *starting point*, not a
  conclusion — question 6 may qualify or reject it for the α=0.01 case.

## Output format

In `RR03-mpl-conf-level-extrapolation.md`: answer each question by number with
your reasoning and evidence; list any additional findings under "Beyond the
brief"; end with concrete recommendations, each marked apply / consider /
reject-with-reason. Where findings bind implementation (e.g. a required MC
sample size, a required sweep cell or diagnostic, or a hold on 0.99), emit a
`## Binding criteria` section: numbered `BC1…`, each a measurable assertion
checkable against evidence, any numeric projection stating its tolerance. These
are ingested verbatim into M90's acceptance criteria and mechanically diffed
against this file.
