# Design

<!-- Seeded by /cairn-init migration (2026-07-12); deepened by /design-interview
     (both phases completed 2026-07-12; D-001..D-003). -->

## Purpose & Scope

`intraclass` estimates interrater-reliability **intraclass correlation
coefficients (ICCs)** within the generalizability-theory framework using **modern
mixed-model variance-component estimation** (linear mixed models) rather than the
classical ANOVA mean-squares approach. It provides the full ICC family (absolute
agreement vs. consistency, single vs. average, fixed vs. random raters, one-way vs.
two-way) with boundary-aware Monte-Carlo confidence intervals, support for
imbalanced/incomplete/multilevel (nested) designs, decision-study projection, and
an interactive helper for choosing the correct coefficient. Multilevel methods
follow ten Hove, Jorgensen & van der Ark (2022, <doi:10.1037/met0000391>).

**Audience (design center):** applied behavioral/clinical researchers who must
report a defensible ICC — defaults, error messages, and the front-door vignettes
optimize for the user who doesn't yet know which ICC they need. Methodologists are
the secondary audience, served by the technical tier (`engines`/`interval-methods`
vignettes, `cairn/estimand-specs/`). (Design interview, 2026-07-12.)

### Contract boundary (elicited 2026-07-12)

- **ICC-only, permanently.** Interrater-reliability ICCs and their intervals are
  the whole job. Categorical agreement (kappa, alpha), internal consistency, and
  general multi-facet G-studies are out forever; requests for other coefficients
  route to other packages.
- **Faithful implementer, never a methods contributor.** Every estimator traces to
  a published primary source (plus the ≥2-oracle bar); parked items stay blocked
  until the literature moves, however tractable a derivation looks.
- **Guidance covers "which," never "how good."** The package guides estimand
  choice and interval reading; it never labels a value poor/good/excellent.
  Qualitative cutoffs are context-dependent and citing them would lend false
  authority — `print`/`summary` stay label-free (vignettes may discuss why
  cutoffs are problematic, with citations).
- **`d_study()` projects reliability inputs only** (rater/occasion counts —
  facets that change the coefficient's value). Precision planning (CI-width
  targeting, "how many subjects for a ±.1 interval?") is a legitimate future
  direction **gated on finding an oracle strategy** (open ROADMAP candidate);
  subject-count-for-power as such is not in scope.

## Commitments & posture (elicited 2026-07-12)

- **Distribution:** CRAN is the canonical channel, with a companion
  software/methods paper as the citation target (the M42 comparison article is a
  paper seed). Release *timing* stays a ROADMAP call.
- **API stability:** exported behavior may change with just a D-entry until the
  first CRAN submission; from then on every breaking change takes a lifecycle
  deprecation cycle — the paper's examples must keep running. Submission is the
  one-way door; pre-CRAN cleanups happen before it.
- **Platforms:** the commitment is exactly the CI matrix — R release on macOS,
  Windows and Ubuntu, plus R devel, oldrel-1 and the declared floor on Ubuntu
  only (corrected M139). That six-config matrix runs on push to the default
  branch; a pull request gets ubuntu-release, windows-release and the floor job.
  The declared floor is `R (>= 4.5.0)` [claim:r-floor-declared] (corrected
  M139): the lowest R release on which the Imports chain installs, measured
  across 4.0.0–4.5.1 rather than read off a `Depends` field.
- **Engine roster: closed at four.** glmmTMB (frequentist default), lme4
  (frequentist oracle), brms (Bayesian), lavaan (SEM) — each paradigm represented
  once. A new engine must enable an estimand the four can't reach, not just be
  another fitter; per-estimator parity cost stays capped at ×4.
- **Contribution posture:** solo-maintained; issues welcome, code contributions
  not solicited (the oracle-first bar is hard to enforce on drive-by PRs).
  External PRs triage through the cairn intake path.

## Architecture

- **Estimation engines** behind one interface: **glmmTMB** (default, `Imports`);
  **lme4**, **brms** (Bayesian), and **lavaan** (SEM) are alternate engines and
  independent oracles, all in `Suggests` behind `rlang::check_installed()` — never
  `Imports` (this package's own non-base Imports are just glmmTMB, cli,
  generics, lifecycle, rlang, tibble; their dependency closures come along as
  usual — glmmTMB imports lme4, so the default engine brings it regardless).
- **Public surface:** `icc()` (fit → estimate → interval), `d_study()`
  (decision-study projection), and `choose_icc()` (selection helper), plus tidy S3
  methods (`print`/`summary`/`format`/`tidy`/`glance`/`autoplot`).
- **Intervals** default to boundary-aware Monte-Carlo CIs from the parameter
  covariance matrix; bootstrap and posterior methods are selectable.
- **Ill-posed designs fail loudly** through a classed `abort_*()` layer.
- **Cross-engine parity** is held by one standing asset,
  `tests/testthat/test-engine-parity-matrix.R` (M49): it enumerates the
  (estimand × engine) grid, pins frequentist point-estimate agreement to
  calibrated tolerances, asserts every documented engine refusal fires, and
  reads `icc()`'s engine roster from its own source so a new engine breaks the
  matrix until a row is added (GP4). Its header carries the "add a row" rule.
  Interval parity and the brms engine's live-Stan agreement are cross-referenced
  to the per-engine tests, not re-run there.

## Conventions

- **Oracle-first:** every exported estimator passes ≥2 independent oracle types;
  no fabricated reference values (cited source or committed seeded script).
- **Oracle records:** the central registry `cairn/references/ORACLES.md` (one
  entry per oracle: ID, type, asserting `test:line`, source, provenance).
  Sources live in `references/BIBLIOGRAPHY.md` + the `<citekey>.md` source
  notes indexed by `references/INDEX.md`. (D-007)
- **Name the estimand before coding;** thin vertical slices; plan before code.
- **All user messaging via `cli`; all errors classed via `rlang::abort()`** — no
  bare `stop()`/`warning()`/`cat()`/`print()`.
- **Format with `air`** (`air format .`); CI enforces `air format --check`;
  `lintr` owns semantic linters only.
- Tracking travels with code (cairn: same commit as the work).
- **Doctrine modules** (`cairn/doctrine/`, transferable craft standards — D-033,
  D-034):
  [`doc-claim-pins.md`](doctrine/doc-claim-pins.md) (pinning documentation
  claims), [`data-raw-checkers.md`](doctrine/data-raw-checkers.md) (what the
  `check-references` CI job runs, what stales each ledger, the
  run-all-four-before-push rule),
  [`source-ingestion.md`](doctrine/source-ingestion.md) (verifying PDF
  extractions), and [`prose-style.md`](doctrine/prose-style.md) (the house
  writing standard R1–R6 for the vignettes, roxygen, `README.Rmd` and
  `NEWS.md`, and what the `data-raw/prose-profile.py` ruler counts).

## Design Principles

Two homes, one taxonomy (D-001): the founding constitution stays in
[`PRINCIPLES.md`](PRINCIPLES.md) as `#1`–`#19`, strength-tagged **[IP]/[GP]** in
place so its ~70 in-code `PRINCIPLES.md #N` citations stay valid (statistical
core #1–#5, #12 and the Fable gate #19 are IP; #6–#10, #13, #18 are GP; #11
amended by D-002; #14–#17 retired into cairn's rulebook by D-003). Of the
principles below, IP1–IP3 / GP1–GP7 were derived by the 2026-07-12 design
interview and GP8–GP9 graduated from `LESSONS.md` at M125 (D-033); numbers run
within each type and are never reused or renumbered (retiring one takes a
D-entry).

### Inviolable (IP)

- IP1: **Faithful implementer.** Every exported statistical method — estimator
  *or interval procedure* — traces to a published primary source; the package
  never ships a novel/unpublished method. Parked capabilities stay blocked until
  the literature moves, however tractable a derivation looks. Numerical
  implementation details (optimizer, parameterization) are fenced off: they need
  correctness, not a citation. (Sharpens `PRINCIPLES.md #1/#4`.)
- IP2: **ICC-only identity.** The contract boundary is the interrater ICC
  family, permanently: categorical agreement, internal consistency, and general
  multi-facet G-studies route to other packages. Scope expansion requires a
  constitutional amendment (D-entry + user decision). Citable record for the
  hypothesis-testing side of this boundary: the ICC-equality cluster in
  `cairn/references/` (`konishi1989`, `donner2002`, `young1998`, `naik2007`,
  and `bhandary2006` by subject).
- IP3: **Which, not how good.** The package never qualitatively labels ICC
  magnitude — no poor/good/excellent, no benchmark cutoffs in output, not even
  opt-in. Guidance covers estimand choice and interval reading; vignettes may
  discuss why cutoffs are problematic, with citations.

### Guiding (GP)

- GP1: **Applied-first design center.** Defaults, error messages, and
  front-door docs optimize for the applied non-expert; the methodologist tier
  (engines/interval-methods vignettes, estimand specs) is secondary. (Sharpens
  `PRINCIPLES.md #13`.)
- GP2: **CRAN is the one-way door.** Exported behavior may change with just a
  D-entry until the first CRAN submission; from then on, breaking changes take a
  lifecycle deprecation cycle — the companion paper's examples must keep
  running.
- GP3: **Platform honesty.** Support commitments are exactly what CI verifies
  (`check-standard.yaml:38`). On `push` to the default branch: R release on
  macOS, Windows and Ubuntu; R devel, oldrel-1 and the declared floor 4.5.0 on
  Ubuntu. On `pull_request`: R release on Ubuntu and Windows, and the declared
  floor 4.5.0 on Ubuntu. No declared floor CI doesn't test.
- GP4: **Engine roster closed at four.** glmmTMB, lme4, brms, lavaan — one per
  paradigm. A new engine must enable an estimand the four cannot reach, not just
  be another fitter; per-estimator parity cost stays capped at ×4.
- GP5: **Fix the evidence, never the bar.** A failing stochastic validation pin
  is answered by strengthening the evidence (more replications, per-rep
  seeding), never by loosening the pin post hoc. A genuinely mis-set pin may be
  corrected prospectively with a D-entry, never to turn a red test green.
  (Canonical citation: legacy ADR-042 Amdt 2.)
- GP6: **Sweep the known failure axis.** A simulation-coverage claim includes
  cells along whatever axis the known failure mode grows (cluster count,
  incidence, raggedness), not just comfortable interior cells. (Canonical
  citation: legacy ADR-046 Amdt 1.)
- GP7: **Guard load-bearing subtleties in code.** A correct-but-non-obvious
  statistical corner ships with a guard test plus an in-place comment naming its
  ADR/D-entry, so a future "simplification" fails a test instead of requiring
  archaeology. (E.g. the fixed-rater 2b moment correction.)
- GP8: **State a verified set procedurally.** A count, list, or enumeration in a
  record, criterion, or sweep the repo keeps editing is stated as the procedure
  that derives it — "every quoted string swept", "the sites matched by
  `<search>`", a computed `setdiff()` — never as a hand-pinned number or member
  list, which goes stale the moment a fact is added. Correcting a stale pinned
  figure means counting the artifact, never incrementing the recorded number —
  and unpinning the count is the durable fix. Run the mechanical sweep once more
  at milestone end over every touched artifact: a hand-list or a per-task check
  goes stale between the writing and the checking, and an enumeration written
  from a reading of code survives to implement unless the deriving comparison is
  actually run before it becomes a promise. (Graduated from LESSONS —
  M70/M110/M118/M124 — at M125.)
- GP9: **Exercise a degenerate guard at the reducer; assert the rule, not the
  platform's arithmetic.** Two rules, one family. *Reachability (M84/M103):*
  whether a degenerate fixture (e.g. SSE = 0) even reaches a guard through
  `icc()` is platform-dependent — the engine fit may crash first, in more than
  one form — so fire a reducer's classed abort by calling the reducer directly
  (`npbootstrap_ci(groups, ...)`, `classical_guard_observed(ss, ...)`, or a
  stub `engine$simulate_refit` for `bootstrap_ci()`), match on the guard being
  unreached rather than on an error string, and reserve the `icc()`-path test
  for the SSA = 0 boundary the engine tolerates; a green local suite is not
  evidence the fixture reaches the guard (PR CI runs only ubuntu + windows;
  macOS is push-to-main). *Arithmetic (M105):* whether a quantity lands exactly
  on a boundary (MSA at 0) is a property of the machine's summation order, not
  of the fixture — recompute it at test time and assert the rule (exactly 0
  aborts, else an interval), keep any recorded column as provenance only, and
  make any anti-vacuity count a floor, never an exact split. (Graduated from
  LESSONS — M84, corrected/extended M103/M105 — at M125.)

## Boundary-fit policy

When a variance component is estimated at or near zero — the boundary of the
parameter space, and the common applied case for interrater data — every engine
and CI method resolves it by one of **three documented behaviors**. This section
is the single home for that policy, consolidating the case law of
ADR-002/003/012/014/023/024/025/031/033/037/038/044 under one statement (recorded
as D-004). It documents *existing* behavior: changing any cell below is a change
to the boundary-aware-interval contract (`PRINCIPLES.md #3`) and takes a D-entry.

- **Smooth (boundary-aware by construction).** The component is held strictly
  positive by the parameterization, so the boundary is approached smoothly with
  no clamp and no abort — via an internal log-SD scale that maps the boundary to
  −∞ (glmmTMB natively; lme4 by delta-transform; lavaan), or via natural-scale
  posterior draws that are positive by construction (brms).
- **Classed deferral.** A boundary fit whose covariance cannot support an
  interval aborts with the classed condition `intraclass_singular_fit`, pointing
  the user at the boundary-robust default engine (glmmTMB).
- **Reach-zero (kept or floored).** A boundary value is admitted rather than
  discarded, so the estimate/interval can reach 0: a resample or posterior draw
  with a component at exactly 0 is a legitimate draw and is **kept**
  (bootstrap, posterior); and the fixed-rater θ²_r **average is floored** at 0
  (never per group; see below).

Fit-time, per engine:

| Engine | Boundary handling | Source |
|---|---|---|
| glmmTMB | Smooth log-SD; the boundary maps to −∞ and the fit stays finite — the reference boundary-robust engine | ADR-002/003 |
| lme4 | Interval draws delta-transformed to log-SD (Smooth); an exactly-singular fit (`lme4::isSingular`) has a singular merDeriv covariance → classed deferral to glmmTMB. The guard was introduced for the two-way-random path (ADR-012) and **reused per shape** as later fits were added (ADR-023 fixed/multilevel; ADR-024 incomplete/ragged) — all 7 fit shapes | ADR-012/023/024 |
| brms | Posterior draws on the natural variance scale, strictly positive → Smooth by construction; the point estimate is the boundary-aware mode of the draws | ADR-033 |
| lavaan | Variances on the log-SD scale (Smooth); a Heywood boundary (non-positive variance, `sv`/`ev` ≤ 0) → classed deferral to glmmTMB | ADR-014/031 |

Interval-time, per CI method:

| CI method | Boundary handling | Source |
|---|---|---|
| Monte-Carlo (default) | Sampled on the engine's internal log scale → boundary-aware by construction; covariance eigenvalues floored at 0 (`pmax`) where a Cholesky factor would fail; a genuinely rank-deficient covariance → classed deferral | ADR-003 |
| Bootstrap | Parametric refit per resample; a singular/boundary refit is a valid draw (variance pinned at 0) and is **kept**. Separately, *non-convergent* refits are discarded: past `warn_frac` a classed warning (`intraclass_bootstrap_dropouts`), past `min_frac` a classed abort (`intraclass_singular_fit`) — never a silent NA interval. At the boundary the point (engine REML) and the endpoints (refit quantiles) are different computations, so `conf.low` may land just **above** the point; both are numerically zero there and neither is clamped (`tests/testthat/fixtures/bootstrap-point-containment.tsv`) | ADR-025; M104 |
| Posterior | The engine's own draws (natural scale), **kept**; percentile or HPDI; boundary-aware mode with bounded-density smoothing; degenerate all-equal draws return the common value | ADR-033/044 |
| Classical one-way (SEARLE exact-F, Burch REML) | Both share a loud guard on MSE = 0 / non-finite F (classed deferral). SEARLE reads MSA only through `F = MSA/MSE`, so at MSA = 0 it reports its attained minimum `-1/(n-1)` — the boundary value, kept; its `unit = "average"` projection reports `-Inf` there, the correct limit and in-support for the projected form under D-010. Burch additionally standardizes its eq. 13 kurtosis term by `sqrt(MSA)`, so at MSA exactly 0 it is undefined and aborts classed (`intraclass_singular_fit`), never reporting the NaN it once did | D-022 (M105); D-012/D-013 |
| MPL (deterministic deviance roots) | A side whose profile deviance never reaches the critical value has its limit AT the [0,1] boundary and reports it on that evidence (explicit sign test); a crossing-indicated root-finding failure aborts classed (`intraclass_engine_error`), never silently reported as a boundary limit | D-019 (M99); D-014/D-015 |

**Fixed-rater θ²_r average-floor (cross-engine).** The fixed-rater θ²_r estimand
adds a boundary-aware *average-floor*: the 2b-corrected per-group draws are
averaged and the **average** is floored at 0 — never per group, since per-group
flooring gives zero boundary coverage. Shared across all four engines' fixed-rater
paths (`theta2r_moment_draws()` / `brms_theta2r_moment_draws()`); ADR-038
(frequentist) / ADR-037 (brms); GP7-guarded.

## Known issues

- **CI's path filter qualifies GP3.** `check-standard.yaml`'s `paths-ignore`
  skips the whole matrix for a diff confined to `cairn/**`, `man/**`,
  `README.md` or `**/*.Rmd`, on both events, so "support commitments are
  exactly what CI verifies" holds for every diff that reaches the package and
  not for those. Surfaced at the M139 review and accepted there (2026-08-26):
  GP3 keeps its wording rather than carrying a filter clause, since a
  docs-only diff changes nothing a platform commitment is about. On a
  `pull_request` the filter reads the whole PR diff, not the pushing commit,
  so a tracking-only commit on a branch that also touched package files still
  re-runs the matrix.

- **brms/Stan verification is structurally weaker than the other engines'.**
  There is no Stan toolchain on CI, MCMC results flake across runs, and a full
  sweep costs ~2 hours, so the Bayesian oracle is verified offline against
  committed fixtures rather than re-run in the matrix. Accepted at the M52 gate
  as inherent: the constraint stands, and M52 shipped the mitigation around it
  — the fixture strategy (constraints, test tiers, fixture lifecycle,
  regeneration protocol) is documented in `data-raw/README.md`, and the
  script-to-fixture map is guarded by `tests/testthat/test-brms-oracle-map.R`
  (GP7). (Constraint confirmed 2026-07-12; rewritten from its resolved form
  at the 2026-09-04 triage pass.)
